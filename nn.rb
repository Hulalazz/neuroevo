require 'nmatrix'
require_relative 'monkey'

# TODO: separate activation functions in class?

class NN
  # Translated from Giuse's MLP Mathematica library

  # layers: list of matrices, each being the weights connecting a
  #    layer's inputs (rows) to a layer's neurons (columns), hence
  #    its shape is [ninputs, nneurs]
  # state: list of (one-dimensional) matrices, each (the output or) an
  #   input to the next layer. This means each matrix is a concatenation
  #   of previous-layer output (or inputs), possibly (recursion) this
  #   layer last inputs, and bias (fixed `1`).
  # act_fn: activation function, I guess the good ol' sigmoid will
  #   do for starters
  # struct: the structure of the network, how many (inputs or)
  #   neurons in each layer, hence it's a list of integers
  attr_reader :layers, :state, :act_fn, :struct


  ## Initialization

  def initialize struct, act_fn: nil
    @struct = struct
    @act_fn = self.class.act_fn(act_fn || :sigmoid)
    # @state holds both inputs, possibly recurrency, and bias
    # it is a complete input for the next layer, hence size from layer sizes
    @state = layer_row_sizes.collect do |size|
      NMatrix.zeros([1, size], dtype: :float64)
    end
    # to this, append a matrix to hold the final network output
    @state.push NMatrix.zeros([1, nneurs(-1)], dtype: :float64)
    reset_state
  end

  def reset_state
    @state.each do |m| # state has only single-row matrices
      # reset all to zero
      m[0,0..-1] = 0
      # add bias to all but output
      m[0,-1] = 1 unless m.object_id == @state.last.object_id
    end
  end

  def init_random
    # Will only be used for testing, no sense optimizing it (NMatrix#rand)
    # Reusing #load_weights instead helps catching bugs
    load_weights nweights.times.collect { rand -1.0..1.0 }
  end

  ## Weight utilities

  # method #deep_reset will be needed when playing with structure modification
  def deep_reset
    # reset memoization
    [:layer_row_sizes, :layer_col_sizes, :nlayers, :layer_shapes,
     :nweights_per_layer, :nweights].each do |sym|
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
    layers.collect &:true_to_a
  end

  def layer_col_sizes # number of neurons per layer (excludes input)
    @layer_col_sizes ||= struct.drop(1)
  end

  # define #layer_row_sizes in child class: number of inputs per layer

  def layer_shapes
    @layer_shapes ||= layer_row_sizes.zip layer_col_sizes
  end

  def nneurs nlay=nil
    nlay.nil? ? struct.reduce(:+) : struct[nlay]
  end

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
    raise "Hell!" unless input.size == struct.first
    raise "Hell!" unless input.is_a? Array
    # load input in first state
    @state[0][0, 0..-2] = input
    # activate layers in sequence
    (0...nlayers).each do |i|
      act = activate_layer i
      @state[i+1][0,0...act.size] = act
    end
    return out
  end

  def out
    state.last.to_flat_a # activation of output layer (as 1-dim Array)
  end

  # define #activate_layer in child class


  ## Activation functions

  def self.act_fn type, *args
    fn = send(type,*args)
    lambda do |inputs|
      NMatrix.build([1, inputs.size], dtype: :float64) do |_,i|
        # single-row matrix, indices are columns
        fn.call inputs[i]
      end
    end
  end

  def self.sigmoid k=0.5
    # k is steepness:  0<k<1 is flatter, 1<k is flatter
    # flatter makes activation less sensitive, better with large number of inputs
    lambda { |x| 1.0 / (Math.exp(-k * x) + 1.0) }
  end

  def self.logistic
    lambda { |x|
      exp = Math.exp(x)
      exp.infinite? ? exp : exp / (1.0 + exp)
    }
  end

  def self.lecun_hyperbolic
    # http://yann.lecun.com/exdb/publis/pdf/lecun-98b.pdf -- Section 4.4
    lambda { |x| 1.7159 * Math.tanh(2.0*x/3.0) + 1e-3*x }
  end


  ## Interface to implement in child class

  [:layer_row_sizes, :activate_layer].each do |sym|
    define_method sym do |*args|
      raise NotImplementedError, "Implement ##{sym} in child class!"
    end
  end
end


class FFNN < NN
  # Feed Forward Neural Network

  def layer_row_sizes
    # inputs (or previous-layer activations) and bias
    @layer_row_sizes ||= struct.each_cons(2).collect {|prev, curr| prev+1}
  end

  def activate_layer i
    act_fn.call( state[i].dot layers[i] )
  end

end


class RNN < NN
  # Recurrent Neural Network

  def layer_row_sizes
    # each row holds the inputs for the next level: previous level's
    # activations (or inputs), this level's last activations
    # (recursion) and bias
    @layer_row_sizes ||= struct.each_cons(2).collect do |prev, rec|
      prev + rec +1
    end
  end

  def activate_layer nlay #_layer
    # NOTE: current layer index corresponds to index of next state!
    previous = nlay     # index of previous layer (inputs)
    current = nlay + 1  # index of current layer (outputs)
    # Copy the level's last-time activation to the input (previous state)
    # NOTE: ranges in NMatrix#[] not reliable! gotta loop :(
    nneurs(current).times do |i| # for each activations to copy
      # Copy output from last-time activation to recurrency in previous state
      @state[previous][0, nneurs(previous) + i] = state[current][0, i]
    end
    act_fn.call( state[previous].dot layers[nlay] )
  end

end
