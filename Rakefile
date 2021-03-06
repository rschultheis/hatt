# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "hatt"
  gem.homepage = "http://github.com/rschultheis/hatt"
  gem.license = "MIT"
  gem.summary = %Q{Make calls to HTTP JSON APIs with ease and confidence}
  gem.description = %Q{convention based approach to interfacing with an HTTP JSON API.}
  gem.email = "robert.schultheis@gmail.com"
  gem.authors = ["Robert Schultheis"]
  gem.files = [
    'lib/**/*',
    'bin/**/*',
    'Readme.md',
    'LICENSE.txt',
    'Gemfile',
    'Gemfile.lock',
    'hatt.gemspec',
  ]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "hatt #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# rake readme converts README.rdoc (for rdoc) into README.md (for github)
require 'rdoc2md'
task :readme do
  readme = File.open("README.rdoc").read
  File.open('README.md', 'w') do |file|
    file.write(Rdoc2md::Document.new(readme).to_md)
  end
end