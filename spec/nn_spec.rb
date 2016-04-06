
describe :NN do
  struct = [2,2,1]

  describe "feed-forward (FFNN)" do
    net = FFNN.new struct

    it "#initialize" do
      assert net.struct == struct
      assert net.act_fn.([1,2,3]) == NN.act_fn(:sigmoid).([1,2,3])
    end

    it "#reset" do
      initial_state = [
        NMatrix[[0,0,1]],
        NMatrix[[0,0,1]],
        NMatrix[[0]]]
      altered_state = initial_state.collect {|m| m+1}
      net.instance_variable_set(:@state, altered_state)
      refute net.state == initial_state
      net.reset_state
      assert net.state == initial_state
    end

    it "#deep_reset" do
      memoized_vars = [:@layer_row_sizes, :@layer_col_sizes, :@nlayers,
        :@layer_shapes, :@nweights_per_layer, :@nweights]
      net.nweights
      net.nlayers
      memoized_vars.each do |sym|
        refute net.instance_variable_get(sym).nil?
      end
      net.deep_reset
      memoized_vars.each do |sym|
        assert net.instance_variable_get(sym).nil?
      end
    end

    it "#nweights" do
      # struct: [2,2,1] => layer_shapes: [[2,3],[1,3]]
      assert net.nweights == 2*3 + 1*3
    end

    it "#layer_shapes" do
      # struct: [2,2,1], remember to add biases
      assert net.layer_row_sizes.size == net.layer_col_sizes.size
      assert net.layer_shapes == [[2+1,2],[2+1,1]]
    end

    context "with random weights" do
      net.init_random

      it "works" do
        assert net.activate([2,2]).size == 1
      end

      it "#nweights and #weights correspond" do
        assert net.nweights == net.weights.flatten.size
      end
    end

    context "with loaded weights" do
      weights = net.nweights.times.collect { |n| 1.0/(n+1) } #avoid 1.0/0

      it "#load_weights" do
        weights_are_safe = weights.dup
        net.load_weights weights_are_safe
        assert weights_are_safe == weights
        assert net.layers.collect(&:to_a).flatten == weights
      end

      it "solves the XOR problem" do
        # http://stats.stackexchange.com/questions/12197/can-a-2-2-1-feedforward-neural-network-with-sigmoid-activation-functions-represe
        # [0,1].repeated_permutation(2).collect{|pair| [pair, pair.reduce(:^)]}
        table = {
          [0,0] => 0,
          [1,0] => 1,
          [0,1] => 1,
          [1,1] => 0
        }
        net = FFNN.new([2,2,1], act_fn: :logistic)
        #              2 in + b -> 3 neur,  2 in + b -> 1 neur
        solution_weights = [ [[1,2],[1,2],[0,0]],  [[-1000],[850],[0]] ]
        net.load_weights solution_weights.flatten
        assert net.weights == solution_weights
        table.each do |input, target|
          assert net.activate(input).first.approximates? target
        end
      end
    end
  end
end

describe RNN do
  net = RNN.new [2,2,1]
  context "with random weights" do
    net.init_random

    it "#nweights and #weights correspond" do
      assert net.nweights == net.weights.flatten.size
    end

    it "#layer_shapes" do
      # struct: [2,2,1], with recurrency and biases
      assert net.layer_shapes == [[2+2+1,2],[2+1+1,1]]
    end

    it "works" do
      assert net.activate([2,2]).size == 1
    end

  end
end
