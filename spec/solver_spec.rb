
describe Solver do
  describe NNCurveFitting do
    context "of the XOR function" do
      # Defining a fitness class is as easy as two methods
      class XorFit < NNCurveFitting
        def input_target_pairs
          [[[0,0],[0]],
           [[1,0],[1]],
           [[0,1],[1]],
           [[1,1],[0]]]
        end
        def error *args
          ErrorFunctions::sum_of_squared_errors *args
        end
        # Plus initializer... this will likely be fixed later
        # ... DEFINITELY gonna be fixed soon, this is so ugly
        def initialize network:
          super network[:type], network[:struct], act_fn: network[:act_fn]
        end
      end

      # The config hash allows for a LOT of flexibility in defining
      # all parameters desired for the run. Just remember: the focus
      # here should be ease of read, rather than write. Make it clear.
      config = {
        id: 1, #__FILE__[/_(\d).rb$/,1], # can get exp id from file name
        description: "XNES 1-neuron prediction of **XOR** function",
        serializer: :json,
        savepath: Pathname.pwd + 'tmp',
        seed: 1,
        optimizer: {
          fit_class: XorFit,
          nes_class: XNES
        },
        fitness: {
          network: {
            type:   :ffnn,
            struct: [2,2,1],
            act_fn: :logistic
          },
        },
        run: {
          ntrain:      15,
          printevery:  false
        }
      }

      # I'll patch in a method to verify the curve has been fit
      class Solver
        def nwrong
          net.load_weights nes.mu.to_a.flatten
          ans = {} # we can drop into debugger and see which are failing
          input_target_pairs.each do |input, trg|
            act = net.activate(input)
            ans[input] = trg.first>0.5 == act.first>0.5 # do they agree?
          end
          ans.values.count(false)
        end
      end

      context "using XNES as optimizer" do
        it "approximates XOR in #{config[:run][:ntrain]} generations" do
          solver = Solver.new config
          # evaluate in temporary directory
          require 'pathname'
          orig = Pathname.pwd
          dir = config[:savepath]
          dumpfile = dir + "results_1.json"
          FileUtils.mkdir_p(dir)
          Dir.chdir(dir)
          refute File.exists? dumpfile
          # solve xor fitting
          solver.run
          assert solver.nwrong == 0
          # it "the state of the search should be correctly dumped" do
          assert File.exists? dumpfile
          loaded = JSON.load File.read dumpfile
          assert solver.nes.dump == loaded
          # finally clean up the directory
          Dir.chdir(orig)
          FileUtils.rm_rf(dir)
        end
      end
    end

  end
end
