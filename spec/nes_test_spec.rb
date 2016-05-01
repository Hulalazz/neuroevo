require_relative '../lib/neuroevo/nes_test'

describe :nes_test do

  describe :sum_of_squares do
    it do
      vals = [1,2,3]
      sum_of_squares(vals).assert == 1+4+9
    end
  end

  describe :fit do
    it do
      inds = [[1,2,3],[3,2,1]]
      val = 1+4+9
      fit(inds).assert == [val, val]
    end
  end

end
