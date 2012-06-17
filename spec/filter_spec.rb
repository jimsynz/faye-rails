require 'spec_helper'

describe FayeRails::Filter do

  before do
    Faye.ensure_reactor_running!
  end

  after do
    EM.stop_event_loop
  end

  let(:default_message) { { 'clientId' => rand(0xffffffffff).to_s(16), 'channel' => '/bogus/channel' } }

  describe "helpful responder" do

    it "should return the message unchanged when #pass is called" do
      Fiber.new do 
        this_fiber = Fiber.current
        filter = FayeRails::Filter.new('/**', :any, Proc.new { message['changes'] = true ; pass })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout
        end
        filter.incoming(default_message, callback)
        Fiber.yield.should == default_message
      end
    end

    it "should return a modified message when #modify is called" do
      Fiber.new do 
        this_fiber = Fiber.current
        filter = FayeRails::Filter.new('/**', :any, Proc.new { message['changes'] = true ; modify_message })
        expected_message = default_message.dup.tap { |m| m['changes'] = true }
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout 
        end
        expected_message = default_message.dup.tap { |m| m['changes'] = true }
        filter.incoming(default_message, callback)
        Fiber.yield.should == expected_message
      end
    end

    it "should return the default error when #block is called without arguments" do
      Fiber.new do 
        this_fiber = Fiber.current
        filter = FayeRails::Filter.new('/**', :any, Proc.new { block })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout 
        end
        filter.incoming(default_message, callback)
        Fiber.yield.should include_hash('error' => "Message blocked by filter")
      end
    end

    it "should return an arbitrary error when #block is called with an argument" do
      Fiber.new do 
        this_fiber = Fiber.current
        error_message = "Better luck next time"
        filter = FayeRails::Filter.new('/**', :any, Proc.new { block error_message })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout 
        end
        filter.incoming(default_message, callback)
        Fiber.yield.should include_hash('error' => error_message)
      end
    end

    it "should return nil when #drop is called" do
      Fiber.new do 
        this_fiber = Fiber.current
        filter = FayeRails::Filter.new('/**', :any, Proc.new { drop })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout 
        end
        filter.incoming(default_message, callback)
        Fiber.yield.should be_nil
      end
    end

    it "should allow callback to be used as per Faye's original API" do
      Fiber.new do 
        this_fiber = Fiber.current
        filter = FayeRails::Filter.new('/**', :any, Proc.new { callback.call(original_message) })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout 
        end
        filter.incoming(default_message, callback)
        Fiber.yield.should == default_message
      end
    end

  end

  describe "channel activities sucrose" do

    it "#subscribing? should return true when a user is subscribing" do
      Fiber.new do
        this_fiber = Fiber.current
        message = default_message.dup.tap { |m| m['subscription'] = m['channel'] ; m['channel'] = '/meta/subscribe' }
        filter = FayeRails::Filter.new('/**', :any, Proc.new { callback.call(subscribing?) })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout
        end
        filter.incoming(message, callback)
        Fiber.yield.should be_true
      end
    end

    it "#subscribing? should return false when a user isn't subscribing" do
      Fiber.new do
        this_fiber = Fiber.current
        filter = FayeRails::Filter.new('/**', :any, Proc.new { callback.call(subscribing?) })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout
        end
        filter.incoming(default_message, callback)
        Fiber.yield.should be_false
      end
    end

    it "#unsubscribing? should return true when a user is unsubscribing" do
      Fiber.new do
        this_fiber = Fiber.current
        message = default_message.dup.tap { |m| m['subscription'] = m['channel'] ; m['channel'] = '/meta/unsubscribe' }
        filter = FayeRails::Filter.new('/**', :any, Proc.new { callback.call(unsubscribing?) })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout
        end
        filter.incoming(message, callback)
        Fiber.yield.should be_true
      end
    end

    it "#unsubscribing? should return false when a user isn't unsubscribing" do
      Fiber.new do
        this_fiber = Fiber.current
        filter = FayeRails::Filter.new('/**', :any, Proc.new { callback.call(unsubscribing?) })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout
        end
        filter.incoming(default_message, callback)
        Fiber.yield.should be_false
      end
    end

    it "#meta? should return true when a message is destined for a meta channel" do
      Fiber.new do
        this_fiber = Fiber.current
        message = default_message.dup.tap { |m| m['channel'] = '/meta/foo' }
        filter = FayeRails::Filter.new('/**', :any, Proc.new { callback.call(meta?) })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout
        end
        filter.incoming(message, callback)
        Fiber.yield.should be_true
      end
    end

    it "#meta? should return false when a isn't destined for a meta channel" do
      Fiber.new do
        this_fiber = Fiber.current
        filter = FayeRails::Filter.new('/**', :any, Proc.new { callback.call(meta?) })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout
        end
        filter.incoming(default_message, callback)
        Fiber.yield.should be_false
      end
    end

    it "#service? should return true when a message is destined for a service channel" do
      Fiber.new do
        this_fiber = Fiber.current
        message = default_message.dup.tap { |m| m['channel'] = '/service/foo' }
        filter = FayeRails::Filter.new('/**', :any, Proc.new { callback.call(meta?) })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout
        end
        filter.incoming(message, callback)
        Fiber.yield.should be_true
      end
    end

    it "#service? should return false when a isn't destined for a service channel" do
      Fiber.new do
        this_fiber = Fiber.current
        filter = FayeRails::Filter.new('/**', :any, Proc.new { callback.call(meta?) })
        callback = ->(message) do
          this_fiber.resume message
        end
        EM.add_timer 5 do
          this_fiber.resume :Timeout
        end
        filter.incoming(default_message, callback)
        Fiber.yield.should be_false
      end
    end

  end

end
