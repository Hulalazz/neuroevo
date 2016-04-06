
describe "Neuroevolution" do
  context "to approximate the XOR function" do
    context "with FFNN (logistic act_fn) as network" do

      class XorErr
        attr_reader :net, :acts, :res, :errs, :err, :xor_table

        XOR = {
          [0,0] => 0,
          [1,0] => 1,
          [0,1] => 1,
          [1,1] => 0
        }

        def initialize
          @net = FFNN.new [2,2,1], act_fn: :logistic
        end

        def call inds
          inds.collect &method(:xor_err)
        end

        def load_weights weights
          net.load_weights weights
        end

        def activate_net
          @acts = {} # more readable than inject - we're testing here!
          XOR.each do |input, _|
            @acts[input] = net.activate(input).first
          end
        end

        def check_results
          @res = {}
          acts.each do |input, trg|
            @res[input] = trg>0.5 == XOR[input]>0.5 # do they agree?
          end
        end

        def compute_error
          @errs = acts.collect { |k,v| (XOR[k] - v)**2 }
          @err = errs.reduce :+
        end

        def xor_err weights
          load_weights weights
          activate_net
          check_results
          compute_error
        end

        def nwrong
          res.values.count(false)
        end
      end

      fit = XorErr.new

      context "with the right weights" do
        it "verifies the fitness is correct" do
          solution_weights = [ [[1,2],[1,2],[0,0]],  [[-1000],[850],[0]] ]
          res = fit.([solution_weights.flatten]).first
          assert res.approximates? 0
        end
      end

      context "using XNES as optimizer" do
        nes = XNES.new fit.net.nweights, fit, :min
        ntrain = 100

        it "consistently approximates XOR in #{ntrain} generations" do
          nes.run ntrain: ntrain, printevery: false
          assert fit.nwrong == 0
        end
      end
    end

  end
end
