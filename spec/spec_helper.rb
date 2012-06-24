# Configure Rails Environment
ENV['RAILS_ENV'] ||= 'test'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}
Dir[File.join(File.dirname(__FILE__), "dummy/spec/**/*.rb")].each {|f| require f}
require 'database_cleaner'
require 'fiber'

Thread.new do
  run Dummy::Application
end

Rails.backtrace_cleaner.remove_silencers!

RSpec.configure do |config|
  config.mock_with :mocha
  config.include(Within)
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  config.after(:suite) do
    DatabaseCleaner.clean
  end
end

