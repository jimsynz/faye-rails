# Configure Rails Environment
ENV['RAILS_ENV'] ||= 'test'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "spec/support/**/*.rb")].each {|f| require f}
Dir[File.join(File.dirname(__FILE__), "dummy/spec/**/*.rb")].each {|f| require f}
require 'database_cleaner'
require 'fiber'

Thread.new do
  run Dummy::Application
end

module Within 

  def within(timeout=5.seconds, &block)
    @timeout = timeout.to_i
    raise ArgumentError "Timeout must be greater than zero seconds" unless @timeout > 0
    @block = block
    raise ArgumentError "Proc doesn't respond to #call" unless @block.respond_to? :call
    raise RuntimeError "Event Machine reactor is not running" unless EM.reactor_running?

    Fiber.new do
      this_fiber = Fiber.current
      EM.add_timer(@timeout) do
        if this_fiber.alive?
          raise RuntimeError "Timeout waiting for test to finish."
        end
      end
      @block.call(this_fiber.method(:resume), *args)
    end.resume
  end
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

