
describe "Neuroevolution" do
  context "to approximate the XOR function" do
    xor_table = {
      [0,0] => 0,
      [1,0] => 1,
      [0,1] => 1,
      [1,1] => 0
    }

    context "with FFNN (logistic act_fn) as network" do
      net = FFNN.new [2,2,1], act_fn: :logistic
      xor_err = lambda do |weights|
        net.load_weights weights
        acts = {} # more readable than inject - we're testing here!
        xor_table.each do |input, _|
          acts[input] = net.activate(input).first
        end
        res = {}
        acts.each do |input, trg|
          res[input] = trg>0.5 == xor_table[input]>0.5 # do they agree?
        end
        require 'pry'; binding.pry if res.values.all?
        errs = acts.collect { |k,v| xor_table[k] - v}
        errs.reduce :+
      end

      context "using XNES as optimizer" do
        fit = lambda { |inds| inds.collect { |ind| xor_err.call ind } }
        nes = XNES.new net.nweights, fit, :min

        it "the fitness is correct",:focus do
          solution_weights = [ [[1,2],[1,2],[0,0]],  [[-1],[8.5],[0]] ]
          res = fit.([solution_weights.flatten]).first
          assert res.approximates? 0
        end

        it "correctly approximates XOR" do
          nes.run ntrain: 5000, printevery: 100
          assert net.out.all? {|v| v.approximates? 0}
        end
      end
    end

  end
end
