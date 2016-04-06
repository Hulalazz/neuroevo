
describe :monkey do

  # describe :Symbol do
  #   it "allows calls with arguments" do
  #     assert [1,2,3].collect(&:+.(1)) == [2,3,4]
  #   end
  # end

  describe Numeric do
    v = 1e-3
    describe "#approximates?" do
      it do
        assert v.approximates? v+1e-4, 1e-3
        refute v.approximates? v+1e-2, 1e-3
      end
    end
  end

  describe NMatrix do
    data = [[1,2,3],[4,5,6],[7,8,9]]
    nmat = NMatrix[*data]
    diag = [1,5,9]

    it "::build" do
      shape = [data.size, data.first.size]
      built = NMatrix.build(shape) {|i,j| data[i][j]**2}
      assert built == nmat**2
    end

    it "#each_diag" do
      assert nmat.each_diag.to_a == diag.collect {|n| NMatrix[[n]]}
    end

    it "#each_stored_diag" do
      assert nmat.each_stored_diag.to_a == diag
    end

    context "when setting the diagonal" do
      set_diag_diag = [10,50,90]
      set_diag_data = [[10,2,3],[4,50,6],[7,8,90]]
      set_diag_nmat = NMatrix[*set_diag_data]

      it "#set_diag" do
        setted = nmat.set_diag {|i| set_diag_diag[i]}
        assert setted == set_diag_nmat
        refute nmat == setted
        refute nmat.object_id == setted.object_id
      end

      it "#set_diag!" do
        tmp_mat = nmat.clone
        setted = tmp_mat.set_diag! {|i| set_diag_diag[i]}
        assert setted == set_diag_nmat
        assert tmp_mat == setted
      end

    end

    describe "#outer" do
      mini = NMatrix[[1,2],[3,4]]
      # Mathematica: `exp = Outer[List, mini, mini]`
      exp = NMatrix[[[[2, 3], [4, 5]],
                     [[3, 4], [5, 6]]],
                                        [[[4, 5], [6, 7]],
                                         [[5, 6], [7, 8]]]]
      it "corresponds to Mathematica values" do
        res = mini.outer(mini) {|a,b| a+b}
        assert res.shape == exp.shape
        assert res == exp
      end

      describe "#outer_flat" do
        exp_flat = NMatrix[[2, 3, 4, 5],
                           [3, 4, 5, 6],
                           [4, 5, 6, 7],
                           [5, 6, 7, 8]]
        it "corresponds to Mathematica values" do
          res = mini.outer_flat(mini) {|a,b| a+b}
          assert res.shape == exp_flat.shape
          assert res == exp_flat
        end
      end
    end

    describe "#eigen" do
      # Mathematica
      m_eigenvalues = NMatrix[[16.11684, -1.11684, 0.0]].transpose
      m_eigenvectors = NMatrix[[0.283349, 0.641675, 1.0],
                               [-1.28335, -0.141675, 1.0],
                               [1.0, -2.0, 1.0]].transpose
      # NMatrix (LAPACK)
      eigenvalues, eigenvectors = nmat.eigen

      def eigencheck? orig, e_vals, e_vecs
        # INPUT: original matrix, eigenvalues accessible by index,
        #        NMatrix with corresponding eigenvectors in columns
        e_vecs.each_column.each_with_index.all? do |e_vec_t, i|
          left = orig.dot(e_vec_t)
          right = e_vec_t * e_vals[i]
          left.approximates? right
        end
      end

      describe "Mathematica values" do
        # Let's first of all check if our values are right
        it "solve the eigendecomposition" do
          assert eigencheck?(nmat, m_eigenvalues, m_eigenvectors)
        end
      end

      describe "eigenvalues" do
        it "correspond to Mathematica values" do
          assert eigenvalues.approximates? m_eigenvalues
        end
      end

      it "solves the eigendecomposition" do
        assert eigencheck?(nmat, eigenvalues, eigenvectors)
      end

    end

    describe "#exponential" do
      testmat = nmat/10.0 # let's avoid 1e6 values, shall we?
      exp = [[1.37316, 0.531485, 0.689809], # MatrixExp[nmat/10]
             [1.00926, 2.24815, 1.48704],
             [1.64536, 1.96481, 3.28426]]
      it "corresponds to Mathematica values" do
        left = testmat.exponential
        right = NMatrix[*exp]
        assert left.approximates? right
      end
    end

    describe "#approximates?" do
      it do
        assert nmat.approximates? nmat+1e-4, 1e-3
        refute nmat.approximates? nmat+1e-2, 1e-3
      end
    end

    # describe "#sort_rows_by" do
    #   it "should be implemented! And used in NES#sorted_inds!"
    # end

    describe "#hjoin" do
      it "should work with smaller matrices" do
        a = NMatrix.new([1,3], [1,2,3])
        b = NMatrix.new([1,2], [4,5])
        expect(a.hjoin(b)).to eq(NMatrix.new([1,5], [1,2,3,4,5]))
      end
      it "should work with larger matrices" do
        a = NMatrix.new([1,3], [1,2,3])
        b = NMatrix.new([1,4], [4,5,6,7])
        expect(a.hjoin(b)).to eq(NMatrix.new([1,7], [1,2,3,4,5,6,7]))
      end
      # it "should be tested also with multirow matrices"
    end

    describe "#vjoin" do
      it "should work with smaller matrices" do
        a = NMatrix.new([3,1], [1,2,3])
        b = NMatrix.new([2,1], [4,5])
        expect(a.vjoin(b)).to eq(NMatrix.new([5,1], [1,2,3,4,5]))
      end
      it "should work with larger matrices" do
        a = NMatrix.new([3,1], [1,2,3])
        b = NMatrix.new([4,1], [4,5,6,7])
        expect(a.vjoin(b)).to eq(NMatrix.new([7,1], [1,2,3,4,5,6,7]))
      end
      # it "should be tested also with multicolumn matrices!"
    end

    describe "#true_to_a" do
      it "should always return an array with the same shape as the matrix" do
        { [2,2] => [[1,2],[3,4]],        # square
          [2,3] => [[1,2,3],[4,5,6]],    # rectangular (h)
          [3,2] => [[1,2],[3,4],[5,6]],  # rectangular (v)
          [1,3] => [[1,2,3]],            # single row => THIS FAILS! WTF!!
          [3,1] => [[1],[2],[3]],        # single column
          [3]   => [1,2,3]               # single-dimensional
        }.each do |shape, ary|
          expect(NMatrix.new(shape, ary.flatten).true_to_a).to eq ary
        end
      end
    end
  end
end

describe NMatrix, :SKIP do

  # method #hconcat doesn't work! => wrote hjoin (and vjoin)
  describe "#concat" do
    it "should work with smaller matrices" do
      a = NMatrix.new([1,3], [1,2,3])
      b = NMatrix.new([1,2], [4,5])
      expect(a.concat(b)).to eq(NMatrix.new([1,5], [1,2,3,4,5]))
    end
    it "should work with larger matrices" do
      a = NMatrix.new([1,3], [1,2,3])
      b = NMatrix.new([1,4], [4,5,6,7])
      expect(a.concat(b)).to eq(NMatrix.new([1,7], [1,2,3,4,5,6,7]))
    end
  end

  # method #to_a not consistent! => wrote true_to_a (fixing it breaks #new)
  describe "#to_a" do
    it "should always return an array with the same shape as the matrix" do
      { [2,2] => [[1,2],[3,4]],        # square
        [2,3] => [[1,2,3],[4,5,6]],    # rectangular (h)
        [3,2] => [[1,2],[3,4],[5,6]],  # rectangular (v)
        [1,3] => [[1,2,3]],            # single row => THIS FAILS! WTF!!
        [3,1] => [[1],[2],[3]],        # single column
        [3]   => [1,2,3]               # single-dimensional
      }.each do |shape, ary|
        expect(NMatrix.new(shape, ary.flatten).to_a).to eq ary
      end
    end
  end

  # method #[] works with ranges only sometimes!
  # case to reproduce: single-row matrix
  describe "#[]" do
    context "with single value on the right" do
      it "should work consistently with ranges" do
        mat = NMatrix.zeros(3)
        assert mat == NMatrix[[0,0,0],[0,0,0],[0,0,0]]
        mat[0,0] = 1
        assert mat == NMatrix[[1,0,0],[0,0,0],[0,0,0]]
        mat[0..1,0..1] = 1
        assert mat == NMatrix[[1,1,0],[1,1,0],[0,0,0]]
        mat[0..1,0..-1] = 1
        assert mat == NMatrix[[1,1,1],[1,1,1],[0,0,0]]
        mat[0..-1,0..1] = 1
        assert mat == NMatrix[[1,1,1],[1,1,1],[1,1,0]]
        mat[0..-1,0..-1] = 1
        assert mat == NMatrix[[1,1,1],[1,1,1],[1,1,1]]
      end
      it "should work with negative indices"
    end

    context "with array of values on the right" do
      it "should work consistently with ranges" do
        mat = NMatrix.zeros(3)
        assert mat == NMatrix[[0,0,0],[0,0,0],[0,0,0]]
        mat[0,0] = [1]
        assert mat == NMatrix[[1,0,0],[0,0,0],[0,0,0]]
        mat[0..1,0..1] = [1]*4
        assert mat == NMatrix[[1,1,0],[1,1,0],[0,0,0]]
        mat[0..1,0..-1] = [1]*6
        assert mat == NMatrix[[1,1,1],[1,1,1],[0,0,0]]
        mat[0..-1,0..1] = [1]*8
        assert mat == NMatrix[[1,1,1],[1,1,1],[1,1,0]]
        mat[0..-1,0..-1] = [1]*9
        assert mat == NMatrix[[1,1,1],[1,1,1],[1,1,1]]
      end
      it "should work with negative indices"
    end
  end
end
