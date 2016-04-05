require 'nmatrix'

# TODO: separate activation functions in class?

class NN
  # Translated from Giuse's MLP Mathematica library

  # layers: list of matrices, each being the weights connecting a
  #    layer's inputs (rows) to a layer's neurons (columns), hence
  #    its shape is [ninputs, nneurs]
  # state: list of (one-dimensional) matrices, each (the network
  #   input or) the output of one layer, and which consequently is
  #   the input of (the recurrent connections and) the next layer
  # act_fn: activation function, I guess the good ol' sigmoid will
  #   do for starters
  # struct: the structure of the network, how many (inputs or)
  #   neurons in each layer, hence it's a list of integers
  attr_accessor :layers, :state, :act_fn, :struct


  ## Initialization

  def initialize struct, act_fn: nil
    @struct = struct
    @act_fn = act_fn || self.class.sigmoid()
    reset_state
  end

  def reset_state
    @state = struct.collect do |layer_size|
      NMatrix.zeros [1, layer_size], dtype: :float64
    end
  end

  def init_random
    # Will only be used for testing, no sense optimizing it (NMatrix#rand)
    # Reusing #load_weights instead helps catching bugs
    load_weights nweights.times.collect { rand -1.0..1.0 }
  end

  ## Weight utilities

  # TODO: #deep_reset will be needed when playing with structure modification
  def deep_reset
    # reset memoization
    [:nweights, :nweights_per_layer, :nlayers, :layer_shapes].each do |sym|
      instance_variable_set sym, nil
    end
    reset_state
  end

  def nweights
    @nweights ||= nweights_per_layer.reduce(:+)
  end

  def nweights_per_layer
    @nweights_per_layer ||= layer_shapes.collect { |shape| shape.reduce(:*) }
  end

  def nlayers
    @nlayers ||= layer_shapes.size
  end

  def weights
    @layers.collect &:true_to_a
  end

  # define #layer_shapes in child class

  def load_weights weights
    raise "Hell!" unless weights.size == nweights
    weights_iter = weights.each
    @layers = layer_shapes.collect do |shape|
      NMatrix.build(shape, dtype: :float64) { weights_iter.next }
    end
    reset_state
    return true
  end


  ## Activation

  def bias
    @bias ||= NMatrix[[1], dtype: :float64]
  end

  def activate input
    raise "Hell!" unless input.size == state[0].size
    state[0] = input.is_a?(NMatrix) ? input : NMatrix[input, dtype: :float64]
    (0...nlayers).each do |i|
      state[i+1] = activate_layer i
    end
    return out
  end

  def out
    state.last # activation of output layer (NMatrix)
  end

  # define #activate_layer in child class


  ## Activation functions
  # TODO: move to class?

  def self.sigmoid k=0.5
    # k is steepness:  0<k<1 is flatter, 1<k is flatter
    # flatter makes activation less sensitive, better with large number of inputs
    lambda do |inputs|
      NMatrix.build([1, inputs.size], dtype: :float64) do |_,i| # single-row matrix column indices
        1.0 / (Math.exp(-k * inputs[i]) + 1.0) # actual sigmoid equation
      end
    end
  end

  def self.logistic
    lambda do |inputs|
      NMatrix.build([1, inputs.size], dtype: :float64) do |_,i| # single-row matrix column indices
        Math.exp(inputs[i]) / (1.0 + Math.exp(inputs[i])) # actual logistic equation
      end
    end
  end

  def self.lecun_hyperbolic
    # http://yann.lecun.com/exdb/publis/pdf/lecun-98b.pdf Section 4.4
    lambda do |inputs|
      NMatrix.build([1, inputs.size], dtype: :float64) do |_,i| # single-row matrix column indices
        1.7159 * Math.tanh(2.0*inputs[i]/3.0) + 1e-3 * inputs[i]
      end
    end
  end


  ## Interface to implement in child class

  [:layer_shapes, :activate_layer].each do |sym|
    define_method sym do |*args|
      raise NotImplementedError, "Method ##{sym} needs to be implemented in child class!"
    end
  end
end


class FFNN < NN
  # Feed Forward Neural Network
  def layer_shapes
    @layer_shapes ||= struct.each_cons(2).collect do |inputs, neurons|
      [inputs+1, neurons] # +1 bias
    end
  end

  def activate_layer i
    # Using #dot (inner product) means the composition
    # function is a weighted sum.
    input = state[i].hjoin(bias) # input+bias
    act_fn.call( input.dot layers[i] )
  end

end


class RNN < NN
  # Recurrent Neural Network
  def layer_shapes
    @layer_shapes ||= struct.each_cons(2).collect do |inputs, neurons|
      [inputs+neurons+1, neurons] # +neurons recurrent, +1 bias
    end
  end

  def activate_layer i
    # Using #dot (inner product) means the composition
    # function is a weighted sum.
    input = state[i].hjoin(state[i+1]).hjoin(bias) # input+recurr+bias
    act_fn.call( input.dot layers[i] )
  end

end
