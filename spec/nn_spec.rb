
describe :NN do
  struct = [2,2,1]
  net = NN.new struct

  it "#initialize" do
    assert net.struct == struct
    assert net.act_fn.([1,2,3]) == NN.sigmoid.([1,2,3])
    assert net.state == [
      NMatrix.zeros([1, 2]),
      NMatrix.zeros([1, 2]),
      NMatrix.zeros([1, 1])]
  end

  it "#reset" do
    initial_state = NN.new(struct).state
    net.instance_variable_set(:@state, 'definitely wrong')
    refute net.state == initial_state
    net.reset_state
    assert net.state == initial_state
  end

  xit "#deep_reset" do
    net.nweights
    refute net.instance_variable_get(:@nweights).nil?
    refute net.instance_variable_get(:@layer_shapes).nil?
    net.deep_reset
    assert net.instance_variable_get(:@nweights).nil?
    assert net.instance_variable_get(:@layer_shapes).nil?
  end

  describe "feed-forward (FFNN)" do
    net = FFNN.new struct

    it "#nweights" do
      # struct: [2,2,1] => layer_shapes: [[2,3],[1,3]]
      assert net.nweights == 2*3 + 1*3
    end

    it "#layer_shapes" do
      # struct: [2,2,1], remember to add biases
      assert net.layer_shapes == [[2+1,2],[2+1,1]]
    end

    context "with random network" do
      net.init_random

      it "works" do
        assert net.activate([2,2]).size == 1
      end

      it "#activate"
      it "state"
    end

    context "with loaded weights" do
      weights = net.nweights.times.collect { |n| 1.0/(n+1) } #avoid 1.0/0
      net.load_weights weights

      it "#load_weights" do
        weights_are_safe = weights.dup
        net.load_weights weights_are_safe
        assert weights_are_safe == weights
        assert net.layers.collect(&:to_a).flatten == weights
      end

      it "works" do
        assert net.activate([2,2]).size == 1
      end

      it "solves the XOR problem" do
        # http://stats.stackexchange.com/questions/12197/can-a-2-2-1-feedforward-neural-network-with-sigmoid-activation-functions-represe
        # [0,1].repeated_permutation(2).collect{|pair| [pair, pair.reduce(:^)]}
        table = {
          [0,0] => 0,
          [1,0] => 1,
          [0,1] => 1,
          [1,1] => 0,
        }
        net = FFNN.new([2,2,1], act_fn: NN.logistic)
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
  context "with random network" do
    net.init_random
    it "works" do
      assert net.activate([2,2]).size == 1
    end
  end
end
