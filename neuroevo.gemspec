
Gem::Specification.new do |s|
  s.name          = 'neuroevo'
  s.version       = `git describe`
  s.platform      = Gem::Platform::RUBY
  s.date          = Date.today.strftime "%Y-%m-%d"
  s.author        = 'Giuseppe Cuccu'
  s.email         = 'giuseppe.cuccu@gmail.com'
  s.summary       = "Porting my neuroevolution research code to Ruby."
  s.description   = %Q[
This is code I'm working on, I'm creating a gem just to easily import it in
a larger framework. It's not intended for distribution as of now, but you're
welcome to play with it :)

UPDATE: This gem is slowly growing into something other people may find
      useful. Version 0.1.6 introduces even documentation! :P
      It's also ever slowly diverging into three largely independent
      projects: a neural network implementation, a black box
      optimizer, and a linear algebra support library. To these I'll
      soon add a definition of "experiment" (not actual name), to
      keep the ecosystem together.

      I am beginning to think this could be useful to any business
      with big data managed by Rails. Well, I am managing my work
      data in a Rails environment, so I get for free browser views
      and database interface, among others.

      Let's see where this thing gets us :)
]

  s.homepage      = 'https://github.com/giuse/neuroevo'
  s.license       = 'MIT'
  s.post_install_message = <<-EOF
************************************************************************
                          BEWARE - HERE BE DRAGONS
************************************************************************
This is working code from me to me. I am not producing community-quality
code ATM, just squeezing back what I need from my old Mathematica code.

The gem build is there for easier import rather than sharing purposes.
I presently consider the future of this code as a future consideration.

That said, if you'd like to make my code your own, you'll find me most
enthusiast :)

Thanks!

EOF

  s.rubyforge_project = "neuroevo" # required for validation
  s.files         = `git ls-files -z`.split("\x0")
  # s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  # s.extensions = "ext/extconf.rb" # C extensions
  s.test_files    = s.files.grep(%r[^(spec)/])
  s.required_ruby_version = '~> 2.0'

  # Install
  s.add_development_dependency 'bundler', '~> 1.12'
  s.add_development_dependency 'rake', '~> 11.1'

  # Test
  s.add_development_dependency 'rspec', '~> 3.4'
  s.add_development_dependency 'ae', '~> 1.8'

  # Debug
  s.add_development_dependency 'pry', '~> 0.10'
  s.add_development_dependency 'pry-nav', '~> 0.2'
  s.add_development_dependency 'pry-rescue', '~> 1.4'
  s.add_development_dependency 'pry-stack_explorer', '~> 0.4'
  s.add_development_dependency 'descriptive_statistics', '~> 2.5'

  # Run
  s.add_runtime_dependency 'nmatrix', '~> 0.2'
  s.add_runtime_dependency 'nmatrix-atlas', '~> 0.2'

end
