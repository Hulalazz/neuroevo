require 'nmatrix'
require 'distribution' # If you have GSL installed and want to speed things up: gem install rb-gsl

# NOTE: objective function should take whole population as input.
# This separates algorithm parallelization from evaluation parallelization.
# TODO: make it accept a single-ind objective function (add param key?)

require File.expand_path(File.dirname(__FILE__) + '/monkey')


class NES
  # Translated from Giuse's NES Mathematica library
  attr_reader :ndims, :mu, :log_sigma, :sigma, :dist, :opt_type, :obj_fn, :id

  def initialize ndims, obj_fn, opt_type
    # opt_type is in [:min, :max] for minimization / maximization
    raise "Hell!" unless [:min, :max].include? opt_type
    @ndims, @opt_type, @obj_fn = ndims, opt_type, obj_fn
    @id = NMatrix.identity(ndims, dtype: :float64)
    @dist = Distribution::Normal.rng(0,1)
    # @dist = Distribution::Uniform.rng(0,1)
    @mu = NMatrix.new([1, ndims], 0, dtype: :float64)
    @log_sigma = NMatrix.identity(ndims, dtype: :float64)
    @sigma = log_sigma.exponential
  end

  def convergence
    # estimate convergence as sum of variances
    sigma.trace
  end

  # Doubling popsize and halving lrate often helps
  def utils;   @utilities ||= hansen_utilities   end
  def popsize; @popsize   ||= hansen_popsize * 2 end
  def lrate;   @lrate     ||= hansen_lrate       end

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

  def hansen_lrate
    (3+Math.log(ndims)) / (5*Math.sqrt(ndims))
  end

  def hansen_popsize
    [5, 4 + (3*Math.log(ndims)).floor].max
  end

  def standard_normal_samples
    NMatrix.build([popsize,ndims], dtype: :float64) {dist.call}
  end

  def move_inds inds
    # TODO: can we get rid of double transpose?
    # sigma.dot(inds.transpose).map(&mu.method(:+)).transpose

    multi_mu = NMatrix[*inds.rows.times.collect {mu.to_a}, dtype: :float64].transpose
    (multi_mu + sigma.dot(inds.transpose)).transpose

    # sigma.dot(inds.transpose).transpose + inds.rows.times.collect {mu.to_a}.to_nm
  end

  # TODO: refactor this, it's THIS open for easier debugging
  def sorted_inds
    # Algorithm equations are meant for fitness maximization
    # Utilities need to be matched with individuals sorted by
    # INCREASING fitness -- reverse order for minimization
    samples = standard_normal_samples
    inds = move_inds(samples).to_a
    fits = obj_fn.(inds)
    # quick cure for NaNs
    fits.map!{ |x| x.nan? ? (opt_type==:max ? -1 : 1) * Float::INFINITY : x }
    fits_by_sample = samples.to_a.zip(fits).to_h
    # http://ruby-doc.org/core-2.2.0/Enumerable.html#method-i-sort_by
    # refactor: compute the fitness directly in sort_by
    sorted_samples = samples.to_a.sort_by { |s| fits_by_sample[s] }
    # ary = inds.to_a.each_with_index.sort_by{|_,i| fits[i]}.collect &:first
    sorted_samples.reverse! if opt_type==:min
    ret = NMatrix[*sorted_samples, dtype: :float64]
    # require 'pry'; binding.pry
    ret
  end

  def train
    raise NotImplementedError, "Implement in child class!"
  end

  def run ntrain: 1, printevery: 1
    ## Set printevery to `false` to disable output printout
    if printevery # Pre-run print
      puts "\n\n    NES training -- #{ntrain} iterations\n"
    end
    # Actual run
    ntrain.times do |i|
      if printevery and i==0 || (i+1)%printevery==0
        puts "\n#{i+1}/#{ntrain}\n  mu:    #{mu}\n  sigma: #{sigma.diagonal}"
      end
      train   #   <== actual training
    end
    # End of run print
    if printevery
      puts "\n    Training complete"

      puts "    mu (avg): #{mu.reduce(:+)/ndims}"
      puts "    convergence: #{convergence}"
    end
  end

end

class XNES < NES
  def train
    picks = sorted_inds
    g_mu = utils.dot(picks)
    g_log_sigma = popsize.times.inject(NMatrix.zeros_like sigma) do |sum, i|
      u = utils[i]
      # TODO: there are no zero-utils, can I optimize this with linear alg?
      next if u.zero? # skip zero-utils calculations
      ind = picks.row(i)
      ind_sq = ind.outer_flat(ind, &:*)
      sum + (ind_sq - id) * u
    end
    @mu += sigma.dot(g_mu.transpose).transpose * lrate
    @log_sigma += g_log_sigma * (lrate/2)
    @sigma = log_sigma.exponential
  end
end
