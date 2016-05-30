require 'forwardable'
require_relative 'time_tracker'

# Allows to define a solution search with a clearly-readable options hash.
# Builds all the necessary framework, runs the optimization, then saves
# the search state.
class Solver
  extend Forwardable

  attr_reader :id, :nes, :fit, :description, :savepath, :ext,
    :serializer, :accessor, :printevery, :nruns, :nrun, :ngens, :ngen,
    :run_tracker, :exec_tracker

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

  def savefile base_name="solver"
    return false unless savepath
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
  # @note the {pre,post}_{gen,run} hooks can be overloaded to alter execution
  def run **config_overload
    with_params_overload config_overload do
      pre_exec
      1.upto(nruns || 1) do |nrun|
        @nrun = nrun
        pre_run
          1.upto(ngens || 1) do |ngen|
            @ngen = ngen
            pre_gen
            nes.train
            post_gen
          end
        post_run
      end
      post_exec
    end
    ## anything happens: drop to pry console
    # rescue Exception => e
    #   require 'pry'; binding.pry
    #   raise
  end

  ### Save and load

  # Save-to-file abstraction
  # @param what what to save
  # @param where where to save it
  # @param verify [Bool] verify saved data
  # @param verbose [Bool] print confirmation if save successful
  # @return [true, false, nil] boolean confirmation if verification
  #   is true, nil otherwise
  def save_something what, where, verify: true, verbose: true
    File.open(where, accessor) do |f|
      serializer.dump what, f
    end
    if verify # else will return `nil`
      success = load(where, false) == what
      if verbose
        puts "Saving < #{where} >" +
          (success ? "\n  => Save successful" : "\n\n\t\tSAVE FAILED!!\n\n")
      end
      success || raise("Hell! Can't save!")
    end
  end

  # Save solver state to file
  # @note currently saving only what I need, which is the NES dump
  # @param verify [Bool] verify saved data
  # @return (see #save_something)
  def save_solution verify=true
    # TODO: dump hash with all data?
    save_something nes.dump, savefile,
      verify: verify, verbose: printevery
  end

  # Save prediction-observation pairs to file - use the distribution
  #   mean as set of weights for prediction
  # @param verify [Bool] verify saved data
  # @return (see #save_something)
  def save_pred_obs verify=true
    save_something fit.pred_obs(nes.mu), savefile("pred_obs"),
      verify: verify, verbose: printevery
  end

  # Load solver execution state
  # @note currently loading only what I need, which is the NES dump.
  #   What I do is I re-load the experiment file, which includes the
  #   parameters hash, then I just load the search state from here.
  #   Check the specs for details.
  def load where, print_confirmation=true
    # They're arrays, you'll need to rebuild the NMatrices to resume.
    serializer.load(File.read where).tap do |res|
      return puts "\n\n\t\tLOAD FAILED!!\n\n" unless res
      puts "Load successful" if print_confirmation
    end
  end

  ### Execution hooks

  def pre_exec
    if printevery && nruns
      @exec_tracker = TimeTracker.new
      exec_tracker.start_tracking
    end
  end

  def pre_run
    if printevery
      @run_tracker = TimeTracker.new
      run_tracker.start_tracking
      puts run_header
    end
  end

  def pre_gen
  end

  def post_gen
    if printevery && (ngen==1 || (ngen)%printevery==0)
      puts gen_summary
    end
  end

  def post_run
    if savefile
      save_solution
      save_pred_obs
    end
    if printevery
      run_tracker.end_tracking
      puts "\n    RUN: #{run_tracker.summary}"
    end
  end

  def post_exec
    if printevery && nruns
      exec_tracker.end_tracking
      puts "\n\nExecution complete\n#{exec_tracker.summary}"
    end
    ## drop to pry console at end of execution
    # require 'pry'; binding.pry
  end

  ### Reporting

  def run_header
    %Q[

    #{description}

    #{run_tracker.start_string}
    #{nes.class} training -- #{ngens} generations -- printing every #{printevery}

    ].gsub('  ', '')
  end

  def gen_summary
    %Q[
      #{ngen}/#{ngens||1}
        mu (avg):    #{nes.mu.reduce(:+)/nes.ndims}
        conv (avg):  #{nes.convergence/nes.ndims}
        mu's fit:    #{fit.([nes.mu]).first}
    ].gsub('      ', '')
  end

end
