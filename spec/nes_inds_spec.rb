
describe :nes do
  describe :inds do

    context "when sorted by fitness" do
      fit = Proc.new{|lst| lst.collect {|ind| ind.reduce :+}}

      context "with artificial inds" do
        inds = [[7,8,9], [1,2,3], [4,5,6]]
        a,b,c = inds
        max_sort = [b,c,a]
        min_sort = max_sort.reverse
        nes = NES.new(a.first.size, fit, :min)
        nes.instance_eval("@popsize = #{inds.size}")
        nes.instance_eval("@mu = NMatrix.zeros([1,3])")
        nes.instance_eval("@sigma = @id.dup")
        nes.instance_eval("@sigma = NMatrix.identity(3)")
        nes.instance_eval("def standard_normal_samples; NMatrix[*#{inds}] end")

        it "minimization" do
          assert nes.sorted_inds.to_a == min_sort
          refute nes.sorted_inds.to_a == max_sort
          refute nes.sorted_inds.to_a == inds
        end

        it "maximization" do
          nes.instance_eval("@opt_type = :max")
          assert nes.sorted_inds.to_a == max_sort
          refute nes.sorted_inds.to_a == min_sort
          refute nes.sorted_inds.to_a == inds
        end
      end

      context "with generated inds" do
        ndims = 5
        nes = NES.new(ndims, fit, :min)
        # fetch individuals through nes sampling
        inds = nes.standard_normal_samples.to_a
        fits = fit.call(inds)
        max_idx = fits.each_with_index.sort.map &:last
        max_sort = inds.values_at *max_idx
        min_sort = max_sort.reverse
        # fix the sampling to last sample
        nes.instance_eval("def standard_normal_samples; NMatrix[*#{inds}] end")
        # fix the sigma not to alter the ind
        nes.instance_eval("@sigma = @id.dup")

        it "minimization" do
          assert nes.sorted_inds.to_a == min_sort
          refute nes.sorted_inds.to_a == max_sort
          refute nes.sorted_inds.to_a == inds && inds != min_sort
        end

        it "maximization" do
          nes.instance_eval("@opt_type = :max")
          assert nes.sorted_inds.to_a == max_sort
          refute nes.sorted_inds.to_a == min_sort
          refute nes.sorted_inds.to_a == inds && inds != max_sort
        end
      end
    end

  end
end
