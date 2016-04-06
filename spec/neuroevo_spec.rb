
describe "Neuroevolution" do
  context "to approximate the XOR function" do
    xor_table = {
      [0,0] => 0,
      [1,0] => 1,
      [0,1] => 1,
      [1,1] => 0,
    }

    context "with FFNN (logistic act_fn) as network" do
      net = FFNN.new [2,2,1], act_fn: :logistic
      xor_err = lambda do |weights|
        net.load_weights weights
        xor_table.inject(0) do |mem, (input, target)|
          mem + target - net.activate(input).first
        end
      end

      context "using XNES as optimizer" do
        fit = lambda { |inds| inds.collect { |ind| xor_err.call ind } }
        nes = XNES.new net.nweights, fit, :min

        it "correctly approximates XOR" do
          nes.run ntrain: 50, printevery: false
          # puts "  weights: #{net.layers}"
          assert net.out.all? {|v| v.approximates? 0}
        end
      end
    end

  end
end
