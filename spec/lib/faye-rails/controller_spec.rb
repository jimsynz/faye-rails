require 'spec_helper'

describe FayeRails::Controller do

  before do
    Faye.ensure_reactor_running!
  end

  after do
    EM.stop_event_loop if EM.reactor_running?
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
        Fiber.yield.should be_truthy
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

    it "should be able to monitor wildcard channels" do
      Fiber.new do
        this_fiber = Fiber.current
        controller.channel('/widgets/*') do
          monitor :publish do
            this_fiber.resume message
          end
        end
        EM.schedule do
          FayeRails.client.publish('/widgets/20', "Rosey, bring me a beer!")
        end
        EM.add_timer 5 do
          this_fiber.resume "timeout"
        end
        Fiber.yield.should == "Rosey, bring me a beer!"
      end
    end


  end

  describe WidgetController do

    before(:all) do
      ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
      ActiveRecord::Migration.create_table :widgets do |t|
        t.string :name
        t.timestamps
      end

      class Widget < ActiveRecord::Base

      end
    end

    after(:all) do
      # Close the connection?!
    end

    let(:controller) { WidgetController }

    it_should_behave_like "channel observer"

    it { WidgetController.should respond_to :observe }
    it { WidgetController.should respond_to :publish }
    it { WidgetController.should respond_to :channel }

    context "observers" do
      it "should observe the addition of a new widget" do
        # Mock the publish method
        # Make sure that the publish method is called like expected
        #WidgetController.expects(:publish).at_least_once
        ValidateScope = Proc.new do |widget|
          # TODO Should be the scope of WidgetController
          #self.should == WidgetController
          widget.instance_of?(Widget).should == true
        end

        # Add observer to the Widget Controller
        class WidgetController < FayeRails::Controller
          observe Widget, :before_validation, &ValidateScope
          observe Widget, :after_validation, &ValidateScope
          observe Widget, :before_save, &ValidateScope
          observe Widget, :before_create, &ValidateScope
          observe Widget, :after_create, &ValidateScope
          observe Widget, :after_save, &ValidateScope
          observe Widget, :after_commit, &ValidateScope
        end

        # Now actually create the widget
        Widget.create name: "Testing!"
      end

      it "should observe and respond to multiple callbacks" do
        # mock the publish method
        # After Commit does not trigger...therefore it will not count
        WidgetController.expects(:publish).at_least(6)
        ValidateMultipleCallbacks = Proc.new do |widget|
          # TODO Should be allowed to call
          #self.publish('/widget', {})
          WidgetController.publish('/widget', {})
        end

        # Add observer to the Widget Controller
        class WidgetController < FayeRails::Controller
          observe Widget, :before_validation, &ValidateMultipleCallbacks
          observe Widget, :after_validation, &ValidateMultipleCallbacks
          observe Widget, :before_save, &ValidateMultipleCallbacks
          observe Widget, :before_create, &ValidateMultipleCallbacks
          observe Widget, :after_create, &ValidateMultipleCallbacks
          observe Widget, :after_save, &ValidateMultipleCallbacks
          observe Widget, :after_commit, &ValidateMultipleCallbacks
        end

        # Now actually create the widget
        Widget.create name: "Testing!"
      end
    end

  end

  describe WidgetController.new do

    let(:controller) { WidgetController.new }

    it_should_behave_like "channel observer"

  end

end
