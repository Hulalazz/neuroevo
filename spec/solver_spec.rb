
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
        #id: 1, #__FILE__[/_(\d).rb$/,1], # can get exp id from file name
        description: "XNES 1-neuron prediction of **XOR** function",
        seed: 1, # fixed seed for deterministic testing
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
          ngens:       15,
          printevery:  false
        }
      }

      # I'll patch in a method to verify how many points have been fit
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
          # solve xor fitting
          solver = Solver.new config
          solver.run
          assert solver.nwrong == 0
        end

        context "saving files" do
          include UsesTemporaryFolders
          in_temporary_folder
          it "the state of the search should be correctly dumped" do
            solver = Solver.new config
            dumpfile = tmp_dir + "results.json"
            refute File.exists? dumpfile
            solver.run savepath: tmp_dir, ngens: 1 # , printevery: 50
            assert File.exists? dumpfile
            loaded = JSON.load File.read dumpfile
            # verify
            assert solver.nes.dump == loaded
          end
        end
      end
    end

  end
end
