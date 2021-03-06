
describe NES do
  describe :hansen do

    class TestNES < NES
      def initialize_distribution
        @mu = NMatrix.zeros([1,@ndims])
        @sigma = NMatrix.identity(@ndims)
      end
    end

    describe :utilities do

      expected = {
        5 => [-0.2, -0.2, -0.2, -0.2, 0.8],
        10 => [-0.1, -0.1, -0.1, -0.1, -0.1, -0.1, -0.1, 0.0215323, 0.192823, 0.485645],
        20 => [-0.05, -0.05, -0.05, -0.05, -0.05, -0.05, -0.05, -0.05, -0.05, -0.05, -0.05, -0.05, -0.0331092, -0.0139599, 0.00814626, 0.0342923, 0.0662925, 0.107548, 0.165694, 0.265096]
      }

      it "correspond to Mathematica values" do
        expected.each do |n, exp|
          nes = TestNES.new(n, Proc.new{}, :min)
          nes.instance_eval("@popsize = n")
          assert nes.hansen_utilities.approximates? NMatrix[exp]
        end
      end
    end

    describe :lrate do
      expected = {
        5 => 0.412281,
        10 => 0.335365,
        20 => 0.268137
      }

      it "correspond to Mathematica values" do
        expected.each do |n, exp|
          nes = TestNES.new(n, Proc.new{}, :min)
          assert nes.hansen_lrate.approximates? exp
        end
      end
    end

    describe :popsize do
      expected = {
        5 => 8,
        10 => 10,
        20 => 12
      }

      it "correspond to Mathematica values" do
        expected.each do |n, exp|
          nes = TestNES.new(n, Proc.new{}, :min)
          assert nes.hansen_popsize == exp
        end
      end
    end

  end
end
