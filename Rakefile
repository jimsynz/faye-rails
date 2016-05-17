require 'bundler'
Bundler::GemHelper.install_tasks
require 'rake/testtask'

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'faye-rails/version'
require 'rspec'
require 'rspec/core/rake_task'

desc "Run only RSpec test examples"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["-c", "-f progress"]
  t.pattern = 'spec/**/*_spec.rb'
end

task :bundle do
  system "bundle"
end

task :import_javascript_client => :bundle do
  system "cp -v `bundle show faye`/lib/faye-browser*.js vendor/assets/javascripts"
  system "sed '/\\/\\/# sourceMappingURL=faye-browser-min.js.map$/d' vendor/assets/javascripts/faye-browser-min.js > vendor/assets/javascripts/faye.js"
end

task :wrap_in_closure => :import_javascript_client do
  Dir['vendor/assets/javascripts/*.js'].each do |file|
    js = File.read(file)
    File.write(file, "(function() {\n#{js}\n})(this);")
  end
end

task :build => [ :wrap_in_closure, :spec ] do
  system "gem build faye-rails.gemspec"
end

task :release => :build do
  system "gem push faye-rails-#{FayeRails::VERSION}.gem"
end

task :default => [ :wrap_in_closure, :spec ]
