####### Monkey patches
####### Don't try this at home kids

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

class NMatrix
  # Dearly-missing initialize with block
  # Note: now NMatrix::random and such are the realy monkey patch
  # This should be the default behavior for initialize!
  def self.build *args
    raise "Hell!" unless block_given?
    new(*args).tap do |m|
      m.each_stored_with_indices do |_,r,c|
        m[r,c] = yield(r,c)
      end
    end
  end

  def each_diag(get_by=:reference)
    # Simple iteration on matrix diagonal, based on #row and #column
    return enum_for(:each_diag, get_by) unless block_given?
    (0...self.shape.min).each do |i|
      yield self.row(i, get_by).column(i, get_by)
    end
    self
  end

  def each_stored_diag(get_by=:reference)
    # Same as above, yielding the value rather than a NMatrix
    return enum_for(:each_stored_diag, get_by) unless block_given?
    raise "Hell!" unless get_by == :reference
    (0...self.shape.min).each do |i|
      yield self[i,i]
    end
    self
  end

  def set_diag &block
    self.clone.set_diag! &block
  end

  def set_diag!
    # Set values on diagonal
    # Should be achieved rather with iterators above - couldn't :(
    raise "Hell!" unless block_given?
    (0...self.shape.min).each do |i|
      self[i,i] = yield i
    end
    self
  end

  def outer other
    # Outer matrix relationship generalization
    # Make a matrix the same shape as `self`; each element is a matrix,
    # with the same shape as `other`, resulting from the interaction of
    # the corresponding element in `self` and all the elements in `other`.
    # NOTE: Map of map does not work as expected!
    # self.map { |v1| other.map { |v2| yield(v1,v2) } }
    # NOTE: this doesn't cut it either... can't capture the structure
    # NMatrix[ *self.collect { |v1| other.collect { |v2| yield(v1,v2) } } ]
    # NOTE: this works only for 2D matrices, same as most other methods here :(
    # NOTE: output size is fixed! Block cannot return matrices in there :(((
    NMatrix.new(self.shape+other.shape).tap do |m|
      self.each_stored_with_indices do |v1,r1,c1|
        other.each_stored_with_indices do |v2,r2,c2|
          m[r1,c1,r2,c2] = yield(v1,v2)
        end
      end
    end
  end

  def outer_flat other
    # TODO: use NMatrix#build
    NMatrix[*self.collect do |v1|
      other.collect do |v2|
        yield(v1, v2)
      end
    end, dtype: :float64]
  end

  def eigen
    # IMPORTANT: requires lapack
    # IMPORTANT: currently fetching only right eigenvectors!
    #            actually left are also computed, then just discarded
    # RETURNS: eigenvalues, left_eigenvectors, right_eigenvectors
    NMatrix::LAPACK.geev(
      self.float_dtype? ? self : self.cast(dtype: :float64))
  end

  def exponential
    # Matrix exponential: e^self (not to be confused with self^n !)
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

  def approximates? other, epsilon=1e-5
    # Only used for testing, should I move to spec_helper?
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

  def hjoin other
    raise "Hell!" unless self.dim == 2 and other.dim == 2
    NMatrix[*self.true_to_a.zip(other.true_to_a).collect { |a,b| a+b }]
  end

  def vjoin other
    raise "Hell!" unless self.dim == 2 and other.dim == 2
    self.transpose.hjoin(other.transpose).transpose
  end

  def true_to_a
    # Fix inconsistent to_a with single row matrices
    dim == 2 && shape[0] == 1 ? [to_a] : to_a
  end
  alias :tto_a :true_to_a

  # Introducing memoization for size
  # I can't believe it's not hardcoded in C++, it's tied to the
  # underlying implementation anyway!
  alias :old_shape :shape
  def shape
    @shape ||= old_shape
  end
  alias :old_size :size
  def size
    @size ||= old_size
  end
  alias :old_reshape :reshape
  def reshape *args
    @size = nil
    @shape = nil
    old_reshape *args
  end

end

#######################################################################

class Numeric
  def approximates? other, epsilon=1e-5
    # Used for testing and NMatrix#approximates?, should I move to spec_helper?
    (self - other).abs < epsilon
  end
end
