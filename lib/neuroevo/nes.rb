require 'nmatrix'
require_relative 'monkey'

# NOTE: objective function should take whole population as input.
# This separates algorithm parallelization from evaluation parallelization.

# Translated from Giuse's NES Mathematica library

class NES
  # Natural Evolution Strategies
  attr_reader :ndims, :mu, :sigma, :opt_type, :obj_fn, :id, :rand

  # NES object initialization
  # @param ndims [Integer] number of parameters to optimize
  # @param obj_fn [#call] any object defining a #call method (Proc, lambda, custom class)
  # @param opt_type [:min, :max] select minimization / maximization of obj_fn
  # @param seed [Integer] allow for deterministic execution on seed provided
  def initialize ndims, obj_fn, opt_type, seed: nil
    raise "Hell!" unless [:min, :max].include? opt_type
    raise "Hell!" unless obj_fn.respond_to? :call
    @ndims, @opt_type, @obj_fn = ndims, opt_type, obj_fn
    @id = NMatrix.identity(ndims, dtype: :float64)
    @rand = Random.new seed || Random.new_seed
    initialize_distribution
  end

  # Box-Muller transform: generates standard (unit) normal distribution samples
  # @return [Float] a single sample from a standard normal distribution
  def standard_normal_sample
    rho = Math.sqrt(-2.0 * Math.log(rand.rand))
    theta = 2 * Math::PI * rand.rand
    tfn = rand.rand > 0.5 ? :cos : :sin
    rho * Math.send(tfn, theta)
  end

  # Memoized automatic magic numbers
  # NOTE: Doubling popsize and halving lrate often helps
  def utils;   @utilities ||= hansen_utilities   end
  # (see #utils)
  def popsize; @popsize   ||= hansen_popsize * 2 end
  # (see #utils)
  def lrate;   @lrate     ||= hansen_lrate       end

  # Magic numbers from CMA-ES (TODO: add proper citation)
  # @return [NMatrix] scale-invariant utilities
  def hansen_utilities
    # Algorithm equations are meant for fitness maximization
    # Match utilities with individuals sorted by INCREASING fitness
    log_range = (1..popsize).collect do |v|
      [0, Math.log(popsize.to_f/2 - 1) - Math.log(v)].max
    end
    total = log_range.reduce(:+)
    buf = 1.0/popsize
    vals = log_range.collect { |v| v / total - buf }.reverse
    NMatrix[vals, dtype: :float64]
  end

  # (see #hansen_utilities)
  # @return [Float] learning rate lower bound
  def hansen_lrate
    (3+Math.log(ndims)) / (5*Math.sqrt(ndims))
  end

  # (see #hansen_utilities)
  # @return [Integer] population size lower bound
  def hansen_popsize
    [5, 4 + (3*Math.log(ndims)).floor].max
  end

  # Samples a standard normal distribution to construct a NMatrix of
  #   popsize multivariate samples of length ndims
  # @return [NMatrix] standard normal samples
  def standard_normal_samples
    NMatrix.build([popsize,ndims], dtype: :float64) {standard_normal_sample}
  end

  # Move standard normal samples to current distribution
  # @return [NMatrix] individuals
  def move_inds inds
    # TODO: can we get rid of double transpose?
    # sigma.dot(inds.transpose).map(&mu.method(:+)).transpose
    multi_mu = NMatrix[*inds.rows.times.collect {mu.to_a}, dtype: :float64].transpose
    (multi_mu + sigma.dot(inds.transpose)).transpose
    # sigma.dot(inds.transpose).transpose + inds.rows.times.collect {mu.to_a}.to_nm
  end

  # Sorted individuals
  # @return standard normal samples sorted by the respective individuals' fitnesses
  def sorted_inds
    # TODO: refactor this, it's THIS open for easier debugging
    # Algorithm equations are meant for fitness maximization
    # Utilities need to be matched with individuals sorted by
    # INCREASING fitness -- reverse order for minimization
    samples = standard_normal_samples
    inds = move_inds(samples).to_a
    fits = obj_fn.(inds)
    # quick cure for fitness NaNs
    fits.map!{ |x| x.nan? ? (opt_type==:max ? -1 : 1) * Float::INFINITY : x }
    fits_by_sample = samples.to_a.zip(fits).to_h
    # http://ruby-doc.org/core-2.2.0/Enumerable.html#method-i-sort_by
    # refactor: compute the fitness directly in sort_by
    sorted_samples = samples.to_a.sort_by { |s| fits_by_sample[s] }
    sorted_samples.reverse! if opt_type==:min
    NMatrix[*sorted_samples, dtype: :float64]
  end

  # @!method interface_methods
  # Declaring interface methods - implement in child class!
  [:train, :initialize_distribution, :convergence].each do |m|
    define_method m do
      raise NotImplementedError, "Implement in child class!"
    end
  end

  # Main run method
  # @param ntrain [Integer] number of generations to train for
  # @printevery [Integer, nil] number of generations between printouts.
  #   Set to nil to disable printing.
  def run ntrain: 10, printevery: 1
    ## Set printevery to `false` to disable output printout
    if printevery # Pre-run print
      puts "\n\n    NES training -- #{ntrain} iterations -- printing every #{printevery} generations\n"
    end
    # Actual run
    ntrain.times do |i|
      if printevery and i==0 || (i+1)%printevery==0
        mu_fit = obj_fn.([mu]).first
        puts %Q[
          #{i+1}/#{ntrain}
            mu (avg):    #{mu.reduce(:+)/ndims}
            conv (avg) : #{convergence/ndims}
            mu's fit:    #{mu_fit}
        ].gsub /^        /, ''
      end
      train   #   <== actual training
    end
    # End-of-run print
    if printevery
      puts "\n    Training complete"
    end
  end
end

class XNES < NES
  # Exponential NES
  attr_reader :log_sigma

  def initialize_distribution
    @mu = NMatrix.new([1, ndims], 0, dtype: :float64)
    @sigma = NMatrix.identity(ndims, dtype: :float64)
    # XNES mostly works with the log of sigma to avoid continuous decompositions
    # question: what is the matrix that, once exponentiated, yields identity?
    @log_sigma = NMatrix.zeros(ndims, dtype: :float64)
  end

  def train
    picks = sorted_inds
    g_mu = utils.dot(picks)
    g_log_sigma = popsize.times.inject(NMatrix.zeros_like sigma) do |sum, i|
      u = utils[i]
      ind = picks.row(i)
      ind_sq = ind.outer_flat(ind, &:*)
      sum + (ind_sq - id) * u
    end
    @mu += sigma.dot(g_mu.transpose).transpose * lrate
    @log_sigma += g_log_sigma * (lrate/2)
    @sigma = log_sigma.exponential
  end

  def convergence
    # Estimate algorithm convergence as total variance
    sigma.trace
  end
end

class SNES < NES
  # Separable NES
  attr_reader :variances

  def initialize_distribution
    @mu = NMatrix.zeros([1, ndims], dtype: :float64)
    @variances = NMatrix.ones([1,ndims], dtype: :float64)
    @sigma = NMatrix.diagonal variances
  end

  def train
    picks = sorted_inds
    g_mu = utils.dot(picks)
    g_sigma = utils.dot(picks**2 - 1)
    @mu += sigma.dot(g_mu.transpose).transpose * lrate
    @variances *= (g_sigma * lrate / 2).exponential
    @sigma = NMatrix.diagonal variances
  end

  def convergence
    # Estimate algorithm convergence as total variance
    variances.reduce :+
  end
end
