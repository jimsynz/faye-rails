# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "faye-rails/version"

Gem::Specification.new do |s|
  s.name        = "faye-rails"
  s.version     = "#{FayeRails::VERSION}"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James Harton"]
  s.email       = ["james@sociable.co.nz"]
  s.homepage    = "https://github.com/jamesotron/faye-rails"
  s.summary     = "Faye bindings for Rails."
  s.license     = 'MIT'

  s.add_dependency "faye", ["~> 0.8"]
  s.add_development_dependency "rails", ["~> 3"]
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "database_cleaner"

  s.files = %w(README.md) + Dir["lib/**/*", "vendor/**/*"]

  s.require_paths = ["lib"]
end
