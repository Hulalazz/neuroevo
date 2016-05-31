
Gem::Specification.new do |s|
  s.name          = 'neuroevo'
  s.version       = `git describe`
  s.platform      = Gem::Platform::RUBY
  s.date          = Date.today.strftime "%Y-%m-%d"
  s.author        = 'Giuseppe Cuccu'
  s.email         = 'giuseppe.cuccu@gmail.com'
  s.summary       = "Neuroevolution in Ruby."
  s.description   = %Q[\
    Born as working code I needed to import in a larger framework,
    this little gem constitutes a basic but de facto very usable
    neuroevolution framework.

    You're welcome to come play with me :)
  ].gsub('  ', '')

  s.homepage      = 'https://github.com/giuse/neuroevo'
  s.license       = 'MIT'
  s.post_install_message = %Q[\
    Thanks for installing neuroevo!
    I wish it will help you achieve your goals.

    It sure is helping me with mine, so we're akin: you're most welcome to
    drop me a mail, and tell me what is your goal (glad to help), and what
    is missing and you can do better (glad to get help).

    Most importantly: have fun! :)
  ].gsub('  ', '')

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
