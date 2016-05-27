
# Curve fitting evolving a neural network
# Provides a callable object scoring a list of weight-lists
# Input-output pairs and error computation need to be defined in children
# This allows for a generic and adaptable curve-fitting interface
class NNCurveFitting
  OPT_TYPE = :min # this is an error minimization task

  attr_reader :net, :error

  def initialize type, struct, act_fn: :logistic
    # type can be :ffnn for feed forward or :rnn for recurrent
    # struct is the neural network structure
    # act_fn is the neural network activation function
    klass = Module.const_get type.upcase
    @net = klass.new struct, act_fn: act_fn
  end

  def call inds
    # As a fitness object, this function is the only one that will be
    # called by the optimizer.
    # @param [Enumerable<ind>]the list of individuals to evaluate
    # @return [Array<Float>] the list of fitnesses, one corresponding to each individual
    itps = input_target_pairs # test all inds on same data
    inds.collect { |ind| fitness ind, itps }
  end

  ## Implement `#input_target_pairs` in child class
  ## arguments: none
  ## returning: list of pairs, network inputs + corresponding targets

  # Calculate fitnesses for a network given its weights, on a set of
  # input-target pairs
  # @param weights [Array] weights of the network
  # @param itps [Array<net_inputs, corresp_targets>] list of input-target pairs
  def fitness weights, itps
    net.load_weights weights
    # TODO: I could have a collect here, save activations or errors to DB maybe
    itps.inject(0.0) do |tot_err, (input, target)|
      activation = net.activate(input)
      tot_err + error(activation, target)
    end
  end

  ## Implement `#error` in child class
  ## arguments: list of activations, list of targets
  ## returning: error between activations and targets
  ##   (you can use functions from ErrorFunctions module below)

  # Pre-baked error functions
  module ErrorFunctions
    module_function

    # TODO: it might be interesting to explicitly include the number of
    # predictions wrong by more than our target tolerance

    # Cumulative sum of squared errors between activations (prediction) and targets
    def sum_of_squared_errors acts, trgs
      acts.zip(trgs).inject(0) { |tot, (a, t)| tot + (a-t)**2 }
    end

    # Cumulative sum of absolute errors between activations (prediction) and targets
    def sum_of_absolute_errors acts, trgs
      acts.zip(trgs).inject(0) { |tot, (a, t)| tot + (a-t).abs }
    end
  end

  # @!method interface_methods
  # Declaring interface methods - implement in child class!
  [:input_target_pairs, :error].each do |name|
    define_method name do |*args|
      raise NotImplementedError, "Implement ##{name} in child class!"
    end
  end

end
