# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
require_relative 'lib/neuroevo/version'

v_from_branch = `git rev-parse --abbrev-ref HEAD`[/\d+.\d+.\d+$/]
v_from_tag = `git describe`
Gem::Specification.new do |s|
  s.name          = 'neuroevo'
  s.version       = v_from_branch || v_from_tag || raise "Missing version"
  s.platform      = Gem::Platform::RUBY
  s.date          = '2016-04-29'
  s.authors       = ['Giuseppe Cuccu']
  s.email         = ['giuseppe.cuccu@gmail.com']
  s.summary       = "Porting of my old neuroevolution research code to Ruby."
  s.description   = "This is code I'm working on, I'm creating a gem just to easily import it in a larger framework. It's not intended for distribution as of now, but you're welcome to play with it :)"
  s.homepage      = 'https://www.github.com/giuseppecuccu/neuroevo'
  s.license       = 'MIT'
  s.post_install_message = <<-EOF
********************************************************************************
                          BEWARE - HERE BE DRAGONS
********************************************************************************
EOF

  s.rubyforge_project = "neuroevo" # required for validation
  s.files         = `git ls-files -z`.split("\x0")
  # s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  # s.extensions = "ext/extconf.rb" # C extensions
  s.test_files    = s.files.grep(%r[^(spec)/])
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.0'

  s.add_development_dependency 'bundler', '~> 1.5'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'ae'
  s.add_development_dependency 'nmatrix'
  s.add_development_dependency 'nmatrix-atlas'
  s.add_development_dependency 'distribution'

end
