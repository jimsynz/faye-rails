# Configure Rails Environment
ENV['RAILS_ENV'] ||= 'test'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}
Dir[File.join(File.dirname(__FILE__), "dummy/spec/**/*.rb")].each {|f| require f}
require 'rspec/autorun'
require 'faye-rails'
require 'database_cleaner'
require 'fiber'

Thread.new do
  run Dummy::Application
end

Rails.backtrace_cleaner.remove_silencers!

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #config.mock_with :mocha
  config.mock_with :rspec

  # Include the Within Module
  config.include(Within)

  # Configure transactions
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  config.after(:suite) do
    DatabaseCleaner.clean
  end

end
