require 'forwardable'
require_relative 'time_tracker'

# Allows to define a solution search with a clearly-readable options hash.
# Builds all the necessary framework, runs the optimization, then saves
# the search state.
class Solver
  extend Forwardable

  attr_reader :id, :nes, :fit, :description, :savepath, :ext, :tt,
    :serializer, :accessor, :printevery, :nruns, :nrun, :ngens, :ngen

  delegate [:net, :input_target_pairs] => :fit

  # This allows me to define a clearly readable options hash in the
  # caller that both documents, defines and initializes the Solver
  # @param id experiment id
  # @param description human-readable description of what to solve
  # TODO: better optimizer description?
  # @param serializer [{:json, :marshal}] serialization class for data dumping
  # @param savepath [file path] path where to save results (`nil` to disable)
  # @param optimizer optimizer options
  # @param fitness options hash for the fitness object
  # @param run options hash for the run
  # @param seed random seed for deterministic execution (`nil` for random)
  def initialize id: nil, description:, serializer: :json, savepath: nil,
      optimizer:, fitness:, run:, seed: nil
    @id = id
    @description = description
    @printevery = run[:printevery] # Set to false to disable printing.
    @ngens = run[:ngens]
    @nruns = run[:nruns]
    @savepath = savepath
    case serializer
    when :json
      require 'json'
      @ext = '.json'
      @serializer = JSON
      @accessor = 'w'
    when :marshal
      @ext = '.mar'
      @serializer = Marshal
      @accessor = 'wb'
    else raise "Hell! Unrecognized serializer!"
    end

    @fit = optimizer[:fit_class].new fitness
    @nes = optimizer[:nes_class].new fit.net.nweights,
      fit, fit.class::OPT_TYPE, seed: seed
  end

  def savefile
    return false unless savepath
    base_name = "results"
    id_part = id && "_#{id}" || ""
    run_part = nruns && "_r#{nrun}" || ""
    savepath + (base_name + id_part + run_part + ext)
  end

  # Temporary parameter overload, useful when calling `run` by hand
  # @param params [Hash] params to overload
  def with_params_overload params
    return yield if params.empty?
    @to_restore = {}
    params.each do |k,v|
      var_name = :"@#{k}"
      @to_restore[var_name] = instance_variable_get var_name
      instance_variable_set var_name, v
    end
    yield
  ensure
    unless @to_restore.nil?
      @to_restore.each { |var,val| instance_variable_set var, val }
      @to_restore = nil
    end
  end

  # Run find me a solution! Go boy!
  # @param config_overload [Hash] if you call manually call `run`
  # you can temporarily overload any instance variable from here
  def run **config_overload
    with_params_overload config_overload do
      pre_run_print
      1.upto(nruns || 1) do |nrun|
        @nrun = nrun
        pre_gen_print
          1.upto(ngens || 1) do |ngen|
            @ngen = ngen
            in_gen_print
            nes.train
          end
        post_gen_print
        save
      end
      post_run_print
    end
    ## drop to pry console at end of execution
    # require 'pry'; binding.pry
    ## anything happens: drop to pry console
    # rescue Exception => e
    #   require 'pry'; binding.pry
    #   raise
  end

  # Save solver state to file
  # @note currently saving only what I need, which is the NES dump
  # @param verification [Bool] verify saved data
  # @return [true, false, nil] boolean confirmation if verification
  #   is true, nil otherwise
  def save verification=true
    # TODO: dump hash with all data?
    return nil unless (filename = savefile)
    File.open(filename, accessor) do |f|
      serializer.dump nes.dump, f
    end
    if verification # else will return `nil`
      success = load(false) == nes.dump
      if printevery
        puts "File: < #{filename} >"
        puts (success ? "Save successful" : "\n\n\t\tSAVE FAILED!!\n\n")
      end
      success || raise("Hell! Can't save!")
    end
  end

  # Load solver execution state
  # @note currently loading only what I need, which is the NES dump.
  #   What I do is I re-load the experiment file, which includes the
  #   parameters hash, then I just load the search state from here.
  #   Check the specs for details.
  def load print_confirmation=true
    # They're arrays, you'll need to rebuild the NMatrices to resume.
    serializer.load(File.read savefile).tap do |res|
      return puts "\n\n\t\tLOAD FAILED!!\n\n" unless res
      puts "Load successful" if print_confirmation
    end
  end

  # Beginning-of-run printout and stats
  def pre_run_print
  end

  # Beginning-of-generation printout and stats
  def pre_gen_print
    return unless printevery
    @tt = TimeTracker.new
    tt.start_tracking
    puts "\n#{description}\n" unless description.nil?
    puts
    puts tt.start_string
    puts "#{nes.class} training -- #{ngens} iterations -- printing every #{printevery} generations\n"
  end

  # Print for each generation
  def in_gen_print
    return unless printevery && (ngen==1 || (ngen)%printevery==0)
    mu_fit = nes.obj_fn.([nes.mu]).first
    puts %Q[
      #{ngen}/#{ngens||1}
        mu (avg):    #{nes.mu.reduce(:+)/nes.ndims}
        conv (avg):  #{nes.convergence/nes.ndims}
        mu's fit:    #{mu_fit}
    ].gsub(/^\ {6}/, '')
  end

  # End-of-run printout and stats
  def post_run_print
  end

  # End-of-generation printout and stats
  def post_gen_print
    return unless printevery
    puts "\n    Training complete"
    puts

    tt.end_tracking
    puts tt.summary
  end

end
