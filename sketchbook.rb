# Only quick sketches here

def main
  check_logistic_shape
end

def check_sigmoid_shape
  fn = lambda { |x| 1 / (Math.exp(-0.5 * x) + 1)}
  data = (-20..20).step(0.01).collect {|x| [x, fn.(x)]}
  plot_with_gnuplot data
end

def check_lecun_hyperbolic_shape
  fn = lambda { 1.7159 * Math.tanh(2*x/3) + 1e-3 * x}
  data = (-20..20).step(0.01).collect {|x| [x, fn.(x)]}
  plot_with_gnuplot data
end

def check_logistic_shape
  fn = lambda { |x| Math.exp(x) / (1 + Math.exp(x))}
  data = (-10..10).step(0.01).collect {|x| [x, fn.(x)]}
  plot_with_gnuplot data
end

def verify_distribution_normal_is_correcty
  require 'distribution'
  require 'csv'

  npoints = 100_000
  dist = Distribution::Normal.rng(0,1)
  points = npoints.times.collect {dist.call}

  # points = CSV.read("norm.csv")
  # points.collect! { |item| item[0].to_f}

  tally = points.each_with_object(Hash.new(0)) do
    |p,h| h[p.round(2)] += 1
  end

  plot_with_gnuplot tally.to_a.sort
end

def plot_with_gnuplot data
  require 'open3'

  gnuplot_commands = <<-End
    set terminal png
    set output "plot.png"

    plot "-" notitle "" with lines
  End

  data.each do |x,y|
    gnuplot_commands << x.to_s + " " + y.to_s + "\n"
  end

  gnuplot_commands << "e\n"

  image, s = Open3.capture2(
    "gnuplot",
    :stdin_data=>gnuplot_commands, :binmode=>true)
end

main
