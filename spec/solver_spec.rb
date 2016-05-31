
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
          # ngens:       15,
          # nruns:       3,
          printevery:  false # 1
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
        include UsesTemporaryFolders

        ngens = 15
        it "approximates XOR in #{ngens} generations" do
          # solve xor fitting
          solver = Solver.new config
          solver.run ngens: ngens
          assert solver.nwrong == 0
        end

        context "the state of the search should be correctly dumped" do
          in_temporary_folder
          solver = Solver.new config

          it "with default run options" do
            dumpfile = tmp_dir + "solver.json"
            refute File.exists? dumpfile
            solver.run savepath: tmp_dir #, ngens: 3, printevery: 1
            assert File.exists? dumpfile
            loaded = JSON.load File.read dumpfile
            # verify
            assert solver.nes.dump == loaded
          end

          it "with experiment id for multiple runs" do
            dumpfile1 = tmp_dir + "solver_1_r1.json"
            dumpfile2 = tmp_dir + "solver_1_r2.json"
            dumpfile3 = tmp_dir + "solver_1_r3.json"
            refute File.exists? dumpfile1
            refute File.exists? dumpfile2
            refute File.exists? dumpfile3
            solver.run savepath: tmp_dir, id: 1, nruns: 3 #, ngens: 1000
            assert File.exists? dumpfile1
            assert File.exists? dumpfile2
            assert File.exists? dumpfile3
            # verify (actually each is verified in #save)
            refute solver.nes.dump == JSON.load(File.read dumpfile1)
            refute solver.nes.dump == JSON.load(File.read dumpfile2)
            assert solver.nes.dump == JSON.load(File.read dumpfile3)
          end
        end

        context "the prediction results of the search should be correctly dumped" do
          in_temporary_folder
          solver = Solver.new config

          it "with experiment id for multiple runs" do
            dumpfile1 = tmp_dir + "pred_obs_1_r1.json"
            dumpfile2 = tmp_dir + "pred_obs_1_r2.json"
            dumpfile3 = tmp_dir + "pred_obs_1_r3.json"
            refute File.exists? dumpfile1
            refute File.exists? dumpfile2
            refute File.exists? dumpfile3
            solver.run savepath: tmp_dir, id: 1, nruns: 3 #, ngens: 1000
            assert File.exists? dumpfile1
            assert File.exists? dumpfile2
            assert File.exists? dumpfile3
            # verify (actually each is verified in #save)
            refute solver.fit.pred_obs == JSON.load(File.read dumpfile1)
            refute solver.fit.pred_obs == JSON.load(File.read dumpfile2)
            assert solver.fit.pred_obs == JSON.load(File.read dumpfile3)
          end
        end
      end
    end

  end
end
