
describe NES do

  # Handy objective functions
  obj_fns = {
    # MINIMIZATION: upper parabolic with minimum in [0]*ndims
    :min => lambda do |inds|
      inds.collect do |ind|
        ind.inject(0) do |mem, var|
          # mem + var**2
          mem + var.abs
        end
      end
    end,

    # MAXIMIZATION: lower parabolic with maximum in [0]*ndims
    :max => lambda do |inds|
      inds.collect do |ind|
        ind.inject(0) do |mem, var|
          # mem - var**2
          mem - var.abs
        end
      end
    end
  }
  opt_types=obj_fns.keys

  describe XNES do
    # Mathematica values to check for exact correspondance
    ndims = 5 # need it out since I reuse it in several places
    m = {
      #### Algorithm constants
      opt_type: :max,
      obj_fn: obj_fns[:max],
      id: NMatrix.identity(ndims),

      #### Optimized parameters
      ndims: ndims,
      popsize: 16,
      lrate: 0.412281,
      utils: NMatrix[
        [-0.0625, -0.0625, -0.0625, -0.0625, -0.0625, -0.0625, -0.0625,
         -0.0625, -0.0625, -0.0625, -0.0322519, 0.00352402, 0.0473102,
          0.10376, 0.183322, 0.319335]],

      #### Algorithm initialization
      init_mu: NMatrix.zeros([1,ndims]),
      init_log_sigma: NMatrix.zeros(ndims),
      init_sigma:  NMatrix.identity(ndims),

      #### Search state after 3 generations

      mu: NMatrix[
        [-0.0722648, 0.471888, -0.633824, -0.0238598, 0.215852]],

      log_sigma: NMatrix[
        [0.561554, 0.0451679, 0.116178, -0.0566093, 0.0520955],
        [0.0451679, 0.6414, -0.023034, -0.00777936, 0.0556042],
        [0.116178, -0.023034, 0.587412, -0.0255132, 0.0858725],
        [-0.0566093, -0.00777936, -0.0255132, 0.564742, 0.123054],
        [0.0520955, 0.0556042, 0.0858725, 0.123054, 0.33955]],

      sigma: NMatrix[
        [1.77243, 0.0831829, 0.211237, -0.097317, 0.0870789],
        [0.0831829,1.90417, -0.0336519, -0.0103613, 0.091144],
        [0.211237, -0.0336519,1.8187, -0.0425435, 0.13904],
        [-0.097317, -0.0103613, -0.0425435, 1.77457,0.19004],
        [0.0870789, 0.091144, 0.13904, 0.19004, 1.42587]],

      #### Individual generation, evaluation and sorting

      samples: NMatrix[
        [-0.711852, 0.476667, -0.342549, -0.564154, 0.781954],
        [0.76503, 0.9, 0.160478, -0.277011, 0.647586],
        [-1.56902, -1.35213, 0.702417, 0.757346, 1.18893],
        [-1.46064, -0.375224, -0.656053, 1.21188, -0.838443],
        [-0.420505, -1.23817, -1.4762, -0.813103, 0.597991],
        [0.138482, -2.61122, -1.2303, -0.471865, -0.723405],
        [0.354887, 0.542859, -0.708161, 0.96674, 0.876119],
        [0.183909, 0.467122, 1.23359, -0.886437, 1.17343],
        [1.88692, -0.00442256, -0.202205, 2.0715, 0.730549],
        [0.101681, 0.114965, 1.41675, 2.19553, -1.06271],
        [0.214327, 0.362019, -1.63861, -0.293707, -1.0089],
        [-0.293479, 0.829926, 0.0437524, 1.50639, -1.68192],
        [-0.017185, 0.650769, 1.73625, 0.0242154, -0.21539],
        [2.2411, -0.97866, -0.80782, -1.26539, 0.476362],
        [0.437641, -0.515891, -1.10436, -0.692001, 1.66246],
        [-1.24387, 2.51843, 0.0814548, -3.26914, -0.935669]],

      inds: NMatrix[
        [-1.24369, 1.40897, -1.2905, -0.797477, 1.15743],
        [1.47581, 2.30577, -0.108822, -0.48297, 1.25754],
        [-2.78752, -2.15643, 0.490815, 1.68287, 1.89283],
        [-3.02189, -0.430999, -2.29103, 2.14131, -1.00196],
        [-1.1012, -1.80817, -3.24801, -1.23657, 0.559266],
        [-0.320981, -4.50843, -2.83475, -0.932773, -1.3023],
        [0.434526, 1.62877, -1.78437, 1.84815, 1.63072],
        [0.741584, 1.45129, 1.8337, -1.44912, 1.95066],
        [3.09111, 0.672352, -0.589391, 3.61601, 1.78698],
        [0.110589, 0.531974, 1.71926, 3.59894, -0.665875],
        [-0.0676769, 1.14529, -3.70865, -0.691691, -1.4547],
        [-0.807216, 1.85741, -0.942115, 2.3478, -1.8399],
        [0.297056, 1.63132, 2.46738, -0.100757, 0.212561],
        [3.81251, -1.12151, -1.4766, -2.35244, 0.64824],
        [0.639338, -0.278192, -2.27193, -0.926189, 2.29233],
        [-1.81358, 5.10978, -0.824198, -5.9115, -1.60701]],

      fits: [-5.89807, -5.63091, -9.01046, -8.88719, -7.95321,
             -9.89923, -7.32654, -7.42635, -9.75585, -6.62664,
             -7.068, -7.79444, -4.70908, -9.4113, -6.40798, -15.2661],

      order: [16, 6, 9, 14, 3, 4, 5, 12, 8, 7, 11, 10, 15, 1, 2, 13],

      ord_fits: [-15.2661, -9.89923, -9.75585, -9.4113, -9.01046, -8.88719,
                 -7.95321, -7.79444, -7.42635, -7.32654, -7.068, -6.62664,
                 -6.40798, -5.89807, -5.63091, -4.70908],

      sorted: NMatrix[
        [-1.24387, 2.51843, 0.0814548, -3.26914, -0.935669],
        [0.138482, -2.61122, -1.2303, -0.471865, -0.723405],
        [1.88692, -0.00442256, -0.202205, 2.0715, 0.730549],
        [2.2411, -0.97866, -0.80782, -1.26539, 0.476362],
        [-1.56902, -1.35213, 0.702417, 0.757346, 1.18893],
        [-1.46064, -0.375224, -0.656053, 1.21188, -0.838443],
        [-0.420505, -1.23817, -1.4762, -0.813103, 0.597991],
        [-0.293479, 0.829926, 0.0437524, 1.50639, -1.68192],
        [0.183909, 0.467122, 1.23359, -0.886437, 1.17343],
        [0.354887, 0.542859, -0.708161, 0.96674, 0.876119],
        [0.214327, 0.362019, -1.63861, -0.293707, -1.0089],
        [0.101681, 0.114965, 1.41675, 2.19553, -1.06271],
        [0.437641, -0.515891, -1.10436, -0.692001, 1.66246],
        [-0.711852, 0.476667, -0.342549, -0.564154, 0.781954],
        [0.76503, 0.9, 0.160478, -0.277011, 0.647586],
        [-0.017185, 0.650769, 1.73625, 0.0242154, -0.21539]],

      g_mu: NMatrix[[0.0864366, 0.524178, 0.742635, -0.10511, 0.18452]],

      g_log_sigma: NMatrix[
        [-0.78038, 0.228713, 0.153751, -0.146037, -0.152102],
        [0.228713, -0.860693, 0.0694165, 0.257809, 0.280433],
        [0.153751, 0.0694165, 0.498862, 0.0480104, -0.369722],
        [-0.146037, 0.257809, 0.0480104, -1.38431, -0.213907],
        [-0.152102, 0.280433, -0.369722, -0.213907, -0.343388]],

      new_mu: NMatrix[[0.0843913, 0.883438, -0.06431, -0.105036, 0.381459]],

      new_log_sigma: NMatrix[
        [0.400686, 0.0923148, 0.147872, -0.0867133, 0.0207411],
        [0.0923148, 0.463976, -0.00872445, 0.0453656, 0.113413],
        [0.147872, -0.00872445, 0.690248, -0.0156163, 0.00965787],
        [-0.0867133, 0.0453656, -0.0156163, 0.27938, 0.0789591],
        [0.0207411, 0.113413, 0.00965787, 0.0789591, 0.268764]],

      new_sigma: NMatrix[
        [1.52308, 0.141131, 0.258175, -0.120303, 0.0332823],
        [0.141131, 1.60833, -0.00389697, 0.0667631, 0.1684],
        [0.258175, -0.00389697, 2.01453, -0.0353979, 0.0166442],
        [-0.120303, 0.0667631, -0.0353979, 1.3333, 0.106416],
        [0.0332823, 0.1684, 0.0166442, 0.106416, 1.32205]]
    }



    describe "#init" do
      it "initializes correctly" do
        opt_type = opt_types.sample # let's try either every now and then
        nes = XNES.new m[:ndims], obj_fns[opt_type], opt_type
        [:ndims, :popsize, :lrate, :utils, :id].each do |key|
          assert nes.send(key).approximates? m[key]
        end

        [:mu, :log_sigma, :sigma].each do |key|
          assert nes.send(key).approximates? m[:"init_#{key}"]
        end

        assert opt_types.include? nes.opt_type
        assert nes.obj_fn == obj_fns[nes.opt_type]
      end
    end

    describe "#train" do
      context "with opt_type = :max" do
        # opt_type fixed to :max to equal Mathematica
        opt_type = :max
        nes = XNES.new m[:ndims], obj_fns[opt_type], opt_type
        # we also fix the samples for the same reason
        nes.instance_eval(
          "def standard_normal_samples; NMatrix[*#{m[:samples].to_a}] end")
        # skip to a state after 3 trainings (from Mathematica)
        nes.instance_eval("@mu = NMatrix[#{m[:mu].to_a}]")
        nes.instance_eval("@log_sigma = NMatrix[*#{m[:log_sigma].to_a}]")
        nes.instance_eval("@sigma = NMatrix[*#{m[:sigma].to_a}]")

        it "steps correspond to Mathematica computation" do

          samples = nes.standard_normal_samples
          assert samples == m[:samples]

          assert nes.mu == m[:mu]
          assert nes.sigma == m[:sigma]

          inds = nes.move_inds(samples)
          assert inds.approximates? m[:inds], 1e-4

          fits = nes.obj_fn.(inds.to_a)
          assert NMatrix[fits].approximates? NMatrix[m[:fits]], 1e-4

          fits_by_sample = samples.to_a.zip(fits).to_h
          # http://ruby-doc.org/core-2.2.0/Enumerable.html#method-i-sort_by
          # refactor: compute the fitness directly in sort_by
          sorted_samples = samples.to_a.sort_by { |s| fits_by_sample[s] }
          # ary = inds.to_a.each_with_index.sort_by{|_,i| fits[i]}.collect &:first
          sorted_samples.reverse! if opt_type==:min
          ret = NMatrix[*sorted_samples, dtype: :float64]

          picks = ret #nes.sorted_inds
          assert picks == m[:sorted]

# missing: fits, order, ord_fits, sorted

          g_mu = nes.utils.dot(picks)
          assert g_mu.approximates? m[:g_mu]
          g_log_sigma = nes.popsize.times.inject(NMatrix.zeros_like nes.sigma) do |sum, i|
            u = nes.utils[i]
            next if u.zero? # skip zero-utils calculations
            ind = picks.row(i)
            ind_sq = ind.outer_flat(ind, &:*)
            sum + (ind_sq - nes.id) * u
          end
          assert g_log_sigma.approximates? m[:g_log_sigma]
          ## this should also work, since sigma is symmetric:
          ## new_mu = nes.mu + g_mu.dot(nes.sigma) * nes.lrate
          new_mu = nes.mu +
            nes.sigma.dot(g_mu.transpose).transpose * nes.lrate
          assert new_mu.approximates? m[:new_mu]
          new_log_sigma = nes.log_sigma + g_log_sigma * (nes.lrate/2)
          assert new_log_sigma.approximates? m[:new_log_sigma]
          new_sigma = new_log_sigma.exponential
          assert new_sigma.approximates? m[:new_sigma]
        end

        it "result corresponds to Mathematica computation" do
          nes.train
          assert nes.mu.approximates? m[:new_mu]
          assert nes.log_sigma.approximates? m[:new_log_sigma]
          assert nes.sigma.approximates? m[:new_sigma]
        end
      end

      context "with opt_type = :min" do
        opt_type = :min
        nes = XNES.new m[:ndims], obj_fns[opt_type], opt_type
        # fix the samples for the same reason
        nes.instance_eval(
          "def standard_normal_samples; NMatrix[*#{m[:samples].to_a}] end")
        # skip to a state after 3 trainings (from Mathematica)
        nes.instance_eval("@mu = NMatrix[#{m[:mu].to_a}]")
        nes.instance_eval("@log_sigma = NMatrix[*#{m[:log_sigma].to_a}]")
        nes.instance_eval("@sigma = NMatrix[*#{m[:sigma].to_a}]")

        it "result corresponds to Mathematica computation" do
          nes.train
          assert nes.mu.approximates? m[:new_mu]
          assert nes.log_sigma.approximates? m[:new_log_sigma]
          assert nes.sigma.approximates? m[:new_sigma]
        end
      end

      describe "full run" do
        opt_type = opt_types.sample # try either :)
        nes = XNES.new m[:ndims], obj_fns[opt_type], opt_type, seed: 1
        # note: `seed: 2` less lucky, for `ntimes = 115` FAILS
        ntimes = 115
        context "within #{ntimes} iterations" do
          it "optimizes the negative squares function" do
            nes.run ntrain: ntimes, printevery: false # 50
            assert nes.mu.all? { |v| v.approximates? 0 }
            assert nes.convergence.approximates? 0
          end
        end
      end
    end

    describe "resuming" do
      it "#dump and #load" do
        opt_type = m[:opt_type]
        nes1 = XNES.new m[:ndims], obj_fns[opt_type], opt_type, seed: 1
        nes1.run ntrain: 3, printevery: false
        savedata1 = nes1.dump
        nes2 = XNES.new m[:ndims], obj_fns[opt_type], opt_type, seed: 2
        nes2.load savedata1
        savedata2 = nes2.dump
        assert savedata1 == savedata2
      end

      it "#resume" do
        opt_type = m[:opt_type]
        nes = XNES.new m[:ndims], obj_fns[opt_type], opt_type, seed: 1
        nes.run ntrain: 4, printevery: false
        run_4_straight = nes.dump

        nes = XNES.new m[:ndims], obj_fns[opt_type], opt_type, seed: 1
        nes.run ntrain: 2, printevery: false
        run_2_only = nes.dump

        # If I resume with a new nes, it works, but results differ because
        # it changes the number of times the rand has been sampled
        nes_new = XNES.new m[:ndims], obj_fns[opt_type], opt_type, seed: 1
        nes_new.resume run_2_only, ntrain: 2, printevery: false
        run_4_resumed_new = nes.dump
        refute run_4_straight == run_4_resumed_new

        # If instead I use a nes with same seed and same number of rand
        # calls, even though I trash the dist info, it yields the same result
        nes.instance_eval("@mu = NMatrix[#{m[:mu].to_a}]")
        nes.instance_eval("@log_sigma = NMatrix[*#{m[:log_sigma].to_a}]")
        nes.instance_eval("@sigma = NMatrix[*#{m[:sigma].to_a}]")
        nes.resume run_2_only, ntrain: 2, printevery: false
        run_4_resumed = nes.dump
        assert run_4_straight == run_4_resumed
      end
    end
  end

  describe SNES do
    describe "full run" do
      opt_type = opt_types.sample # try either :)
      nes = SNES.new 5, obj_fns[opt_type], opt_type, seed: 1
      # note: `seed: 2` less lucky, for `ntimes = 110` FAILS
      ntimes = 110
      context "within #{ntimes} iterations" do
        it "optimizes the negative squares function" do
          nes.run ntrain: ntimes, printevery: false # 50
          assert nes.mu.all? { |v| v.approximates? 0 }
          assert nes.convergence.approximates? 0
        end
      end
    end
  end

end
