####### Monkey patches
####### Kids don't try this at home


require 'nmatrix'
require 'nmatrix/lapack_plugin' # works for both atlas and lapacke

#######################################################################

# class Symbol
#   # this beauty comes from http://stackoverflow.com/questions/23695653/can-you-supply-arguments-to-the-mapmethod-syntax-in-ruby
#   def call(*args, &block)
#     ->(caller, *rest) { caller.send(self, *rest, *args, &block) }
#   end
# end

#######################################################################

# I see a future where this gem will be matrix-agnostic, allowing to
# duck-type whatever matrix implementation of your preference.

# I am going to propose these patches (and the specs!) to the NMatrix guys as soon as I can get around it, but I don't expect them to integrate these changes. Their work had clearly different objectives then what I need, and it would be rude and preposterous to expect them to change course on my whims.

# I am lucky I can depend on NMatrix right now. But what I long for is the best linear algebra matrix ever written for any language, the love child of matematicians, statisticians, and engineers with both C and Ruby background. I want the best features of NMatrix, CBLAS, Matrix, Daru, Distribution, StatSample, and whatever else the users ever wish for. It should come obvious to use to anyone who can read a linear algebra paper and has basic ruby experience. It should look like pseudocode, not like c-ported-to-ruby, not like hey-I-know-a-better-way, not like I-could-really-use-this-method-right-now.

# If anyone is willing to fund me on this, I'll accept the challenge at a moment's notice.

# Meanwhile, MINASAW: it's time for ducks and monkeys!

# What I wish NMatrix was like (sort of)
class NMatrix
  # Dearly-missed `#initialize` with block.
  # Methods such as NMatrix::random should just be syntactic sugar
  # on top of this. `#initialize` has no reason not to accept a block
  # by default, this should be the default behavior. And coded in C.
  def self.build *args
    raise "Hell!" unless block_given?
    new(*args).tap do |m|
      m.each_stored_with_indices do |_,r,c|
        m[r,c] = yield(r,c)
      end
    end
  end

  # Simple iteration on matrix diagonal, based on `#row` and `#column`
  def each_diag(get_by=:reference)
    return enum_for(:each_diag, get_by) unless block_given?
    (0...self.shape.min).each do |i|
      yield self.row(i, get_by).column(i, get_by)
    end
    self
  end

  # (see #each_diag)
  # Yielding the value rather than a NMatrix
  def each_stored_diag(get_by=:reference)
    return enum_for(:each_stored_diag, get_by) unless block_given?
    raise "Hell!" unless get_by == :reference
    (0...self.shape.min).each do |i|
      yield self[i,i]
    end
    self
  end

  # Sets the diagonal with a block. Couldn't get it to work with `#each_diag` :(
  def set_diag!
    # Set values on diagonal
    # Should be achieved rather with iterators above - couldn't :(
    raise "Hell!" unless block_given?
    (0...self.shape.min).each do |i|
      self[i,i] = yield i
    end
    self
  end

  # (see #set_diag!)
  # Non-destructive version.
  def set_diag &block
    self.clone.set_diag! &block
  end

  # Outer matrix relationship generalization.
  # Make a matrix the same shape as `self`; each element is a matrix,
  # with the same shape as `other`, resulting from the interaction of
  # the corresponding element in `self` and all the elements in `other`.
  # @param other [NMatrix] other matrix
  # @note This implementation works only for 2D matrices (same as most
  #   other methods here). It's a quick hack, a proof of concept barely
  #   sufficient for my urgent needs.
  # @note Output size is fixed! Since NMatrix does not graciously yield to
  #   being composed of other NMatrices (by adapting the shape of the root
  #   matrix), the block cannot return matrices in there.
  # @return [NMatrix]
  def outer other
    # NOTE: Map of map in NMatrix does not work as expected!
    # self.map { |v1| other.map { |v2| yield(v1,v2) } }
    # NOTE: this doesn't cut it either... can't capture the structure
    # NMatrix[ *self.collect { |v1| other.collect { |v2| yield(v1,v2) } } ]
    NMatrix.new(self.shape+other.shape).tap do |m|
      self.each_stored_with_indices do |v1,r1,c1|
        other.each_stored_with_indices do |v2,r2,c2|
          m[r1,c1,r2,c2] = yield(v1,v2)
        end
      end
    end
  end

  # Flattened generalized outer relationship. Same as `#outer`, but the
  # result is a 2-dim matrix of the interactions between all the elements
  # in `self` (as rows) and all the elements in `other` (as columns)
  # @todo use `NMatrix#build` to get rid of intermediate array
  # @param other [NMatrix] other matrix
  # @return [NMatrix]
  def outer_flat other
    NMatrix[*self.collect do |v1|
      other.collect do |v2|
        yield(v1, v2)
      end
    end, dtype: :float64]
  end

  # Calculate matrix eigenvalues and eigenvectors using LAPACK
  # @return [Array<NMatrix, NMatrix, NMatrix>]
  #   eigenvalues (as column vector), left eigenvectors, right eigenvectors
  # @note requires LAPACK
  def eigen
    NMatrix::LAPACK.geev(
      self.float_dtype? ? self : self.cast(dtype: :float64))
  end

  # Matrix exponential: `e^self` (not to be confused with `self^n`!)
  # @return [NMatrix]
  def exponential
    # special cases: one-dimensional matrix: just exponentiate the values
    if self.dim == 1 or self.dim == 2 && self.shape.include?(1)
      NMatrix.new self.shape, self.collect(&Math.method(:exp))
    else
      # Eigenvalue decomposition method from scipy/linalg/matfuncs.py#expm2
      values, _, vectors = eigen
      e_vecs_inv = vectors.invert
      diag_e_vals_exp = NMatrix.diagonal values.collect &Math.method(:exp)
      vectors.dot(diag_e_vals_exp).dot(e_vecs_inv)
    end
  end

  # Small testing helper. Verifies if all corresponding values between `self`
  # and `other` are within `epsilon`.
  # @param other [NMatrix]
  # @param epsilon [Float]
  def approximates? other, epsilon=1e-5
    raise "Hell!" unless self.shape == other.shape or self.shape.size != 2
    # two ways to go here:
    # - epsilon is global: total cumulative accepted error
    # (self - other).reduce(:+) < epsilon
    # - epsilon is local: per element accepted error
    # I choose local to avoid possibility of errors with
    # opposite signs balancing up (law of large numbers)
    self.each_stored_with_indices.all? do |v,r,c|
      v.approximates? other[r,c], epsilon
    end
  end

  # Join two matrices side by side (left: `self`, right: `other`)
  # @param other [NMatrix]
  # @return [NMatrix]
  def hjoin other
    raise "Hell!" unless self.dim == 2 and other.dim == 2
    NMatrix[*self.true_to_a.zip(other.true_to_a).collect { |a,b| a+b }]
  end

  # Join two matrices one above the other (above: `self`, below: `other`)
  # @param other [NMatrix]
  # @return [NMatrix]
  def vjoin other
    raise "Hell!" unless self.dim == 2 and other.dim == 2
    self.transpose.hjoin(other.transpose).transpose
  end

  # NMatrix#to_a is inconsistent with single-row matrices: they are
  # converted to one-dimensional Arrays rather than an Array with
  # only one Array inside. I cannot monkey-patch `#to_a` directly as
  # the constructor (!!!) seems to depend on it, and I have no time
  # to investigate further.
  # @return [Array<Array>] what IMHO `#to_a` should return
  def true_to_a
    dim == 2 && shape[0] == 1 ? [to_a] : to_a
  end
  alias :tto_a :true_to_a

  # @private
  alias :old_shape :shape
  # @private
  alias :old_size :size
  # @private
  alias :old_reshape :reshape

  # Introducing memoization for size and shape.
  # Profiling pointed me to these very common-use methods.
  # I found out they're not memoized in C, as could be expected since
  # the C implementation doesn't allow flexibility anyway, and the only
  # way to change them is through `#reshape`.
  def shape
    @shape ||= old_shape
  end
  # (see #shape)
  def size
    @size ||= old_size
  end
  # (see #shape)
  def reshape *args
    @size = nil
    @shape = nil
    old_reshape *args
  end

end

#######################################################################

# Synctactic sugar cube for testing and debugging
class Numeric
  # Verifies if `self` and `other` are withing `epsilon` of each other.
  # @param other [Numeric]
  # @param epsilon [Numeric]
  # @return [Boolean]
  def approximates? other, epsilon=1e-5
    # Used for testing and NMatrix#approximates?, should I move to spec_helper?
    (self - other).abs < epsilon
  end
end
