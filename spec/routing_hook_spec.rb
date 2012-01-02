require 'spec_helper'

describe "Routing hooks" do

  shared_examples_for "an automatically added route" do

    it "should only be one route" do
      routes.size.should be(1)
    end

    it "should route to FayeRails::RackAdapter" do
      routes.first.app.should be_a(FayeRails::RackAdapter)
    end

  end

  shared_examples_for "a Faye server" do
    self.use_transactional_fixtures = false

    it "should have Event Machine reactor running" do
      Faye.ensure_reactor_running!
      EM.reactor_running?.should be_true
    end

    it "should be able to subscribe to channel" do
      Fiber.new do
        this_fiber = Fiber.current
        channel = "/random/#{rand(65534).to_s}"
        FayeRails.server.bind(:subscribe) do |client_id, _channel|
          this_fiber.resume _channel if _channel == channel
        end
        EM.defer do
          client.subscribe(channel) do |msg|
          end
        end
        EM.add_timer(5) do
          this_fiber.resume "timeout" if this_fiber.alive?
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
        EM.defer do
          client.publish(channel, message)
        end
        EM.add_timer(5) do
          this_fiber.resume "timeout" if this_fiber.alive?
        end
        Fiber.yield.should == message
      end.resume
    end

  end

  describe "/faye_without_websockets" do

    let(:routes) { Dummy::Application.routes.routes.select { |v| v.path =~ /^\/faye_without_websockets.*$/ } }
    let(:client) { Faye::Client.new("http://localhost:3000/faye_without_websockets") }

    it_should_behave_like "an automatically added route"
    it_should_behave_like "a Faye server"

    it "should have websockets disabled" do
      routes.first.app.instance_variable_get(:@enable_websockets).should be(false)
    end

  end

  describe "/faye_with_websockets" do

    let(:routes) { Dummy::Application.routes.routes.select { |v| v.path =~ /^\/faye_with_websockets.*$/ } }
    let(:client) { Faye::Client.new("ws://localhost:3000/faye_with_websockets") }

    it_should_behave_like "an automatically added route"
    it_should_behave_like "a Faye server"

    it "should have websockets enabled" do
      routes.first.app.instance_variable_get(:@enable_websockets).should be(true)
    end

  end

  describe "/faye_with_extension" do
    let(:routes) { Dummy::Application.routes.routes.select { |v| v.path =~ /^\/faye_with_extension.*$/ } }
    let(:client) { Faye::Client.new("http://localhost:3000/faye_with_extension") }

    it_should_behave_like "an automatically added route"
    it_should_behave_like "a Faye server"

    it "should be extended with MockExtension" do
      routes.first.app.instance_variable_get(:@server).instance_variable_get(:@extensions).should include(MockExtension)
    end

  end

end
