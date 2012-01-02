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

    it "should receive messages after subscribe" do
      Fiber.new do
        this_fiber = Fiber.current
        WidgetController.subscribe('/widgets/1') do |message|
          this_fiber.resume message
        end
        FayeRails.client.publish('/widgets/1', "Welcome to Cogswell Sprockets.")
        Fiber.yield.should == "Welcome to Cogswell Sprockets."
      end.resume
    end
    
    it "should be able to subscribe to multiple channels" do
      2.upto(10).each do |i|
        Fiber.new do
          this_fiber = Fiber.current
          WidgetController.subscribe("/widgets/#{i}") do |message|
            this_fiber.resume message
          end
          FayeRails.client.publish("/widgets/#{i}", "Message number #{i}")
          Fiber.yield.should == "Message number #{i}"
        end.resume
      end
    end

    it "should be able to publish messages" do
      Fiber.new do
        this_fiber = Fiber.current
        WidgetController.subscribe('/widgets/11') do |message|
          this_fiber.resume message
        end
        WidgetController.new.publish('/widgets/11', "Welcome to Cogswell Sprockets.")
        Fiber.yield.should == "Welcome to Cogswell Sprockets."
      end.resume
    end

  end

end
