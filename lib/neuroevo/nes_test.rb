require_relative 'nes'



# TODO: CHECK NEURAL NETWORKS TRAINING!! does it use sq_error?
# TODO: CHECK BEHAVIOR WITH NaN / Infinity! Convergence? Divergence?



def sum_of_squares values
  values.collect { |v| v**2 }.reduce(:+)
end

def fit inds
  inds.collect {|x| sum_of_squares(x) }
end

if __FILE__ == $0

  puts "\n  Loading complete"


  ndims = 3
  opt_type = :min
  ntrain = 5000

  nes = XNES.new(ndims, method(:fit), opt_type)

  puts "  Begin training..."
  ntrain.times do |i|
    # puts "  #{i}/#{ntrain}\tError: #{sum_of_squares(nes.mu)}  \tmu avg: #{nes.mu.reduce(:+)/nes.ndims}\tconv: #{nes.convergence}"
    if i%100==0
      puts "#{nes.mu}"
      puts " d- #{nes.sigma.diagonal}"
    end
    nes.train
  end
  puts "  Training finished"

  puts "  mu (avg): #{nes.mu.reduce(:+)/nes.ndims}"
  puts "  convergence: #{nes.convergence}"
  require 'pry'; binding.pry


end

