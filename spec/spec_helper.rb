# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/spec/spec_helper.rb', __FILE__)
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
  config.include(Within)
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

