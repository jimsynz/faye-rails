require 'spec_helper'

describe FayeRails::Controller do

  before do
    Faye.ensure_reactor_running!
  end

  after do
    EM.stop_event_loop
  end

  shared_examples_for "model observer" do
    self.use_transactional_fixtures = false
    
    it "should fire after record creation" do
      Fiber.new do
        this_fiber = Fiber.current
        controller.observe(Widget, :create) do |record|
          this_fiber.resume record.message
        end
        EM.add_timer 5 do
          this_fiber.resume 'timeout'
        end
        EM.schedule do
          Widget.create(:message => 'pass')
        end
        Fiber.yield.should == 'pass'
      end.resume
    end

    it "should fire before record update" do
      Fiber.new do
        this_fiber = Fiber.current
        controller.observe(Widget, :update, :before) do |record|
          this_fiber.resume record.message
        end
        EM.add_timer 5 do
          this_fiber.resume 'timeout'
        end
        EM.schedule do
          instance = Widget.create(:message => 'original')
          instance.message = 'updated'
          instance.save
        end
        Fiber.yield.should == 'updated'
      end.resume
    end

    it "should fire after record destruction" do
      Fiber.new do
        this_fiber = Fiber.current
        controller.observe(Widget, :destroy, :after) do |record|
          this_fiber.resume record.destroyed?
        end
        EM.add_timer 5 do
          this_fiber.resume 'timeout'
        end
        EM.schedule do
          Widget.create(:message => 'created').delete
        end
        Fiber.yield.should == true
      end.resume
    end

  end

  shared_examples_for "channel observer" do

    it "should receive messages after subscribe" do
      Fiber.new do
        this_fiber = Fiber.current
        controller.channel('/widgets/1') do
          subscribe do
            this_fiber.resume message
          end
        end
        EM.schedule do
          FayeRails.client.publish('/widgets/1', "Welcome to Spacely Space Sprockets.")
        end
        EM.add_timer 5 do
          this_fiber.resume "timeout"
        end
        Fiber.yield.should == "Welcome to Spacely Space Sprockets."
      end.resume
    end

    it "should not receive messages after unsubscribe" do
      Fiber.new do
        this_fiber = Fiber.current
        controller.channel('/widgets/99') do
          subscribe do
            this_fiber.resume message
          end
          unsubscribe
        end
        EM.schedule do
          FayeRails.client.publish('/widgets/99', "Welcome to Spacely Sprockets.")
        end
        EM.add_timer 1 do
          this_fiber.resume 'timeout'
        end
        Fiber.yield.should == 'timeout'
      end.resume
    end
    
    it "should be able to subscribe to multiple channels" do
      2.upto(10).each do |i|
        Fiber.new do
          this_fiber = Fiber.current
          controller.channel("/widgets/#{i}") do
            subscribe do
              this_fiber.resume message
            end
          end
          EM.schedule do
            FayeRails.client.publish("/widgets/#{i}", "Message number #{i}")
          end
          EM.add_timer 5 do
            this_fiber.resume "timeout"
          end
          Fiber.yield.should == "Message number #{i}"
        end.resume
      end
    end

    it "should be able to publish messages" do
      Fiber.new do
        this_fiber = Fiber.current
        controller.channel('/widgets/11') do
          subscribe do
            this_fiber.resume message
          end
        end
        EM.schedule do
          controller.new.publish('/widgets/11', "Welcome to Spacely Space Sprockets.")
        end
        EM.add_timer 5 do
          this_fiber.resume "timeout"
        end
        Fiber.yield.should == "Welcome to Spacely Space Sprockets."
      end.resume
    end

    it "should be able to monitor subscription events" do
      Fiber.new do
        this_fiber = Fiber.current
        controller.channel('/widgets/12') do
          monitor :subscribe do
            this_fiber.resume true
          end
        end
        EM.schedule do
          FayeRails.client.subscribe('/widgets/12') { |message| }
        end
        Fiber.yield.should be_true
      end.resume
    end

    it "should be able to monitor publish events" do
      Fiber.new do
        this_fiber = Fiber.current
        controller.channel('/widgets/13') do
          monitor :publish do
            this_fiber.resume message
          end
        end
        EM.schedule do
          FayeRails.client.publish('/widgets/13', "Rosey, bring me a beer!")
        end
        EM.add_timer 5 do
          this_fiber.resume "timeout"
        end
        Fiber.yield.should == "Rosey, bring me a beer!"
      end
    end

  end

  describe WidgetController do

    let(:controller) { WidgetController }

    it_should_behave_like "model observer"
    it_should_behave_like "channel observer"

  end

  describe WidgetController.new do
    
    let(:controller) { WidgetController.new }

    it_should_behave_like "model observer"
    it_should_behave_like "channel observer"

  end

end
