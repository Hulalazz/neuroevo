require 'bundler'
require 'bundler/gem_tasks'
require 'rake'
require 'rspec/core/rake_task'

# Ensure bundle
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

# Open a console ready for testing
desc "Open `pry` with neuroevo preloaded"
task :console do
  sh "pry -I lib -r neuroevo.rb"
end

# Run tests with RSpec
RSpec::Core::RakeTask.new(:spec)

# Run tests by default
task :default => :spec
