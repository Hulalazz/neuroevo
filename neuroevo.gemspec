# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'neuroevo/version'

Gem::Specification.new do |s|
  s.name          = 'neuroevo'
  s.version       = Neuroevo::VERSION
  s.date          = '2016-04-29'
  s.authors       = ['Giuseppe Cuccu']
  s.email         = ['giuseppe.cuccu@gmail.com']
  s.summary       = %q{Porting of my old neuroevolution research code to Ruby.}
  s.description   = %q{Porting of my old neuroevolution research code to Ruby.}
  s.homepage      = 'https://www.github.com/giuseppecuccu/neuroevo'
  s.license       = 'MIT'
  s.post_install_message = <<-EOF
********************************************************************************
                          BEWARE - HERE BE DRAGONS
********************************************************************************
EOF

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(spec)/})
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.0'
# require 'pry'; binding.pry
  s.add_development_dependency 'bundler', '~> 1.5'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'ae'
  s.add_development_dependency 'nmatrix'
  s.add_development_dependency 'nmatrix-atlas'
  s.add_development_dependency 'distribution'

  root_path = File.expand_path(File.dirname(__FILE__))

  # get an array of submodule dirs by executing 'pwd' inside each submodule
  `git submodule --quiet foreach pwd`.split($\).each do |submodule_path|
    # for each submodule, change working directory to that submodule
    Dir.chdir(submodule_path) do
      # issue git ls-files in submodule's directory
      submodule_files = `git ls-files`.split($\)

      # prepend the submodule path to create absolute file paths
      submodule_files_fullpaths = submodule_files.map do |filename|
        "#{submodule_path}/#{filename}"
      end

      # remove leading path parts to get paths relative to the gem's root dir
      # (this assumes, that the gemspec resides in the gem's root dir)
      submodule_files_paths = submodule_files_fullpaths.map do |filename|
        str = filename.gsub root_path, ''
        str[1..(str.length-1)]
      end

      # add relative paths to gem.files
      s.files += submodule_files_paths
    end
  end
end
