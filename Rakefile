require 'bundler'
Bundler::GemHelper.install_tasks
require 'rake/testtask'

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'faye-rails/version'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

task :bundle do
  system "bundle"
end

task :import_javascript_client => :bundle do
  system "cp -v `bundle show faye`/lib/faye-browser-min.js vendor/assets/javascripts"
end

task :build => [ :import_javascript_client, :test ] do
  system "gem build faye-rails.gemspec"
end

task :release => :build do
  system "gem push faye-rails-#{FayeRails::VERSION}.gem"
end

task :default => :test
