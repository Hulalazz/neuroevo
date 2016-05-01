
v_from_branch = `git rev-parse --abbrev-ref HEAD`[/\d+.\d+.\d+$/]
v_from_tag = `git describe`
Gem::Specification.new do |s|
  s.name          = 'neuroevo'
  s.version       = v_from_branch || v_from_tag || raise("Missing version")
  s.platform      = Gem::Platform::RUBY
  s.date          = '2016-04-29'
  s.author        = 'Giuseppe Cuccu'
  s.email         = 'giuseppe.cuccu@gmail.com'
  s.summary       = "Porting of my old neuroevolution research code to Ruby."
  s.description   = "This is code I'm working on, I'm creating a gem just to easily import it in a larger framework. It's not intended for distribution as of now, but you're welcome to play with it :)"
  s.homepage      = 'https://www.github.com/giuseppecuccu/neuroevo'
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

  # Run
  s.add_runtime_dependency 'nmatrix', '~> 0.2'
  s.add_runtime_dependency 'nmatrix-atlas', '~> 0.2'
  s.add_runtime_dependency 'distribution', '~> 0.7'

end
