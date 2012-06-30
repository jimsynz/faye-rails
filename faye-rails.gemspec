# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "faye-rails/version"

Gem::Specification.new do |s|
  s.name        = "faye-rails"
  s.version     = "#{FayeRails::VERSION}"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James Harton", "Ryan Lovelett"]
  s.email       = ["james@sociable.co.nz", "ryan@lovelett.me"]
  s.homepage    = "https://github.com/jamesotron/faye-rails"
  s.summary     = "Faye bindings for Rails 3.1+."
  s.license     = 'MIT'

  s.add_dependency "faye", ["~> 0.8.2"]
  s.add_development_dependency "rails", ["~> 3.1"]
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "mocha"
  s.add_development_dependency "thin"

  s.files = %w(README.md) + Dir["lib/**/*", "vendor/**/*"]

  s.require_paths = ["lib"]
end
