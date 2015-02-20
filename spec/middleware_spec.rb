require 'spec_helper'

describe "Routing hooks" do
  shared_examples_for "a Faye server" do
    self.use_transactional_fixtures = false

    before do
      Faye.ensure_reactor_running!
    end

    after do
      EM.stop_event_loop if EM.reactor_running?
    end

    it "should have Event Machine reactor running" do
      EM.reactor_running?.should be_truthy
    end

    it "should be able to subscribe to channel" do
      Fiber.new do
        this_fiber = Fiber.current
        channel = "/random/#{rand(65534).to_s}"
        FayeRails.server.bind(:subscribe) do |client_id, _channel|
          this_fiber.resume _channel if _channel == channel
        end
        EM.schedule do
          client.subscribe(channel) { |msg| }
        end
        EM.add_timer 5 do
          this_fiber.resume "timeout"
        end
        Fiber.yield.should == channel
      end.resume
    end

    it "should be able to publish to channel" do
      Fiber.new do
        this_fiber = Fiber.current
        channel = "/random/#{rand(65534).to_s}"
        message = "Welcome to the Jungle"
        FayeRails.client.subscribe(channel) do |msg|
          this_fiber.resume msg
        end
        EM.schedule do
          client.publish(channel, message)
        end
        EM.add_timer 5 do
          this_fiber.resume "timeout"
        end
        Fiber.yield.should == message
      end.resume
    end

  end

  let(:middleware) { Dummy::Application.middleware.select {|m| m == FayeRails::Middleware } }

  describe 'middlware stack' do
    it "should contain two instance of Faye::Rails" do
      middleware.count.should == 2
    end
  end

  describe "/faye" do
    let(:client) { Faye::Client.new("http://localhost:3000/faye_without_extension") }
    it_should_behave_like "a Faye server"
  end

  describe "/faye_with_extension" do
    let(:client) { Faye::Client.new("http://localhost:3000/faye_with_extension") }

    it_should_behave_like "a Faye server"

    it "should be extended with MockExtension" do
      server = FayeRails.servers.select {|server| server.endpoint =~ /faye_with_extension/ }.first
      extensions = server.server.instance_variable_get :@extensions

      extension = extensions.detect do |extension|
        extension.instance_of? Dummy::Application::MockExtension
      end
      extension.should_not be_nil
    end
  end
end
