require 'spec_helper'

describe FayeRails::Controller do

  describe "model observer" do
    
    it "should fire after record creation" do
      WidgetController.observe(Widget, :create) do |record|
        record.message = 'pass'
        record.save
      end
      instance = Widget.create(:message => 'fail')
      instance.message.should == 'pass'
    end

    it "should fire before record update" do
      WidgetController.observe(Widget, :update, :before) do |record|
        record.message = 'updated'
      end
      instance = Widget.create(:message => 'original')
      instance.touch
      instance.save
      instance.message.should == 'updated'
    end

    it "should fire after record destruction" do
      WidgetController.observe(Widget, :destroy, :after) do |record|
        record.destroyed?.should == true
      end
      instance = Widget.create(:message => 'created')
    end

  end

  describe "channel observer" do

    before do
      Faye.ensure_reactor_running!
    end

    after do
      EM.stop_event_loop
    end

    it "should receive messages after subscribe" do
      Fiber.new do
        this_fiber = Fiber.current
        WidgetController.channel('/widgets/1') do
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
    
    it "should be able to subscribe to multiple channels" do
      2.upto(10).each do |i|
        Fiber.new do
          this_fiber = Fiber.current
          WidgetController.channel("/widgets/#{i}") do
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
        WidgetController.channel('/widgets/11') do
          subscribe do
            this_fiber.resume message
          end
        end
        EM.schedule do
          WidgetController.new.publish('/widgets/11', "Welcome to Spacely Space Sprockets.")
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
        WidgetController.channel('/widgets/12') do
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
        WidgetController.channel('/widgets/13') do
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
        Fiber.yeild.should == "Rosey, bring me a beer!"
      end
    end

  end

end
