# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/spec/spec_helper.rb', __FILE__)
require 'database_cleaner'

Rails.backtrace_cleaner.remove_silencers!

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end
  config.before(:each) do
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
