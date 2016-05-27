require 'forwardable'

# Allows to define a solution search with a clearly-readable options hash.
# Builds all the necessary framework, runs the optimization, then saves
# the search state.
class Solver
  extend Forwardable

  attr_reader :id, :nes, :fit, :run_opts, :description,
    :save_file, :serializer, :accessor

  delegate [:net, :input_target_pairs] => :fit

  # This allows me to define a clearly readable options hash in the
  # caller that both documents, defines and initializes the Solver
  # @param id experiment id
  # @param description human-readable description of what to solve
  # TODO: better optimizer description?
  # @param serializer serialization class for data dumping
  # @param optimizer optimizer description
  # @param fitness options hash for the fitness object
  # @param run options hash for the run
  def initialize id:, description:, serializer:, savepath: nil,
      optimizer:, fitness:, run:, seed: nil
    @id  = id
    @run_opts = run
    @description = description
    case serializer
    when :json
      require 'json'
      ext = 'json'
      @serializer = JSON
      @accessor = 'w'
    when :marshal
      ext = 'mar'
      @serializer = Marshal
      @accessor = 'wb'
    else raise "Hell! Unrecognized serializer!"
    end
    @save_file = savepath + "results_#{id}.#{ext}" unless savepath.nil?

    @fit = optimizer[:fit_class].new fitness
    @nes = optimizer[:nes_class].new fit.net.nweights,
      fit, fit.class::OPT_TYPE, seed: seed
  end

  # Run find me a solution! Go boy!
  def run
    pre_run_print if run_opts[:printevery]
    nes.run run_opts
    post_run_print if run_opts[:printevery]
    save run_opts[:printevery] unless save_file.nil?

    # drop to pry console at end of execution
    # require 'pry'; binding.pry

  # anything happens: drop to pry console
  # rescue Exception => e
    # require 'pry'; binding.pry
    # raise
  end

  # Save solver execution
  # @note currently saving only what I need, which is the NES dump
  def save verification=true
    # TODO: dump hash with all data?
    File.open(save_file, accessor) do |f|
      serializer.dump nes.dump, f
    end
    if verification # else will return `nil`
      (load(false) == nes.dump).tap do |saved|
        puts (saved ? "Save successful" : "\n\n\t\tSAVE FAILED!!\n\n")
      end
    end
  end

  # Load solver execution state
  # @note currently loading only what I need, which is the NES dump.
  #   What I do is I re-load the experiment file, which includes the
  #   parameters hash, then I just load the search state from here.
  #   Check the specs for details.
  def load print_confirmation=true
    # They're arrays, you'll need to rebuild the NMatrices to resume.
    serializer.load(File.read save_file).tap do |res|
      return puts "\n\n\t\tLOAD FAILED!!\n\n" unless res
      puts "Load successful" if print_confirmation
    end
  end

  # Beginning-of-run printout and stats
  def pre_run_print
    @start = Time.now()
    puts "\n#{description}\n" unless description.nil?
    puts
    puts "Starting execution at #{@start}"
  end

  # End-of-run printout and stats
  def post_run_print
    puts
    puts "Started execution at #{@start}"
    @finish = Time.now()
    puts "Ended execution at #{@finish}"
    time_difference = Time.at(@finish-@start).utc.strftime("%H:%M:%S")
    puts "Time elapsed: #{time_difference}."
  end

end
