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

    before do
      Faye.ensure_reactor_running!
    end

    after do
      EM.stop_event_loop
    end

    it "should have Event Machine reactor running" do
      EM.reactor_running?.should be_true
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

  describe "/faye" do

    let(:routes) { Dummy::Application.routes.routes.select { |v| v.name =~ /^faye_without_extension.*$/ } }
    let(:client) { Faye::Client.new("http://localhost:3000/faye_without_extension") }

    it_should_behave_like "an automatically added route"
    it_should_behave_like "a Faye server"

  end

  describe "/faye_with_extension" do
    let(:routes) { Dummy::Application.routes.routes.select { |v| v.name =~ /^faye_with_extension.*$/ } }
    let(:client) { Faye::Client.new("http://localhost:3000/faye_with_extension") }

    it_should_behave_like "an automatically added route"
    it_should_behave_like "a Faye server"

    it "should be extended with MockExtension" do
      extension = routes.first.app.instance_variable_get(:@server).instance_variable_get(:@extensions).detect do |extension|
        extension.instance_of? MockExtension
      end
      extension.should_not be_nil
    end

  end

  describe Rails::Application::RoutesReloader do

    let (:routes_reloader) do
      Dummy::Application.routes_reloader
    end

    it "should respond to clear_without_faye_servers!" do
      routes_reloader.respond_to?(:clear_without_faye_servers!, true).should be_true
    end

    it "should respond to clear_with_faye_servers!" do
      routes_reloader.respond_to?(:clear_with_faye_servers!).should be_true
    end

    it "should alias clear! to clear_with_faye_servers!" do
      routes_reloader.method(:clear!).should == routes_reloader.method(:clear_with_faye_servers!)
    end

  end

end
