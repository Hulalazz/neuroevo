require_relative 'nes'
require_relative 'nn'

xor_table = {
  [0,0] => 0,
  [1,0] => 1,
  [0,1] => 1,
  [1,1] => 0,
}

net = FFNN.new [2,2,1], act_fn: NN.logistic
xor_err = lambda do |weights|
  net.load_weights weights
  xor_table.inject(0) do |mem, (input, target)|
    mem + target - net.activate(input).first
  end
end

fit = lambda { |inds| inds.collect { |ind| xor_err.call ind } }
nes = XNES.new net.nweights, fit, :min

nes.run ntrain: 100, printevery: 10
puts "  weights: #{net.layers}"

# require 'pry'; binding.pry
