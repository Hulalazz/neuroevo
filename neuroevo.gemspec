
Gem::Specification.new do |s|
  s.name          = 'neuroevo'
  s.version       = `git describe`
  s.platform      = Gem::Platform::RUBY
  s.date          = Date.today.strftime "%Y-%m-%d"
  s.author        = 'Giuseppe Cuccu'
  s.email         = 'giuseppe.cuccu@gmail.com'
  s.summary       = "Neuroevolution in Ruby."
  s.description   = <<-END
    Born as working code I needed to import in a larger framework,
    this little gem constitutes a basic but de facto usable neuroevolution
    framework, extremely easy to start with.
    You're welcome to come play with me :)

    5 main blocks compose it:
      - a linear algebra library, currently mostly NMatrix with few extensions
      - a neural network implementation, for the generic function approximator
      - a black-box optimizer, searching for the network's weights
      - a complex fitness setup (for starters, any callable object will do)
      - a solver / execution manager, easy to configure and extend
    Choices are currently very limited (e.g. 2 networks and 2 optimizers), but
    as long as I will need this gem at work, it is guaranteed to grow.
    Collaborations are most welcome.

    Check the spec for neuroevo to learn it bottom-up.
    Check the spec for solver to learn it top-down.

    If your business is backed by a Rails CMS, and linear regression is not
    sufficient to predict trends in your data, have it a go with NNCurveFitting.
    I am using it on my job, and am extremely satisfied by the results.
  END
  s.description.gsub! ' '*4, ''

  s.homepage      = 'https://github.com/giuse/neuroevo'
  s.license       = 'MIT'
  s.post_install_message = <<-END
    Thanks for installing neuroevo!
    I wish it will help you achieve your goals.

    It sure is helping me with mine, so we're akin: you're most welcome to
    drop me a mail, and tell me what is your goal (glad to help), and what
    is missing and you can do better (glad to get help).

    Most importantly: have fun! :)
  END
  s.post_install_message.gsub! ' '*4, ''

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
