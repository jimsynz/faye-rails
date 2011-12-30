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
      require 'faye'
      FayeRails.server= Faye::RackAdapter.new(:mount => '/faye', :timeout => 25)
      # Try five up to five times to open a listening socket
      # because inability to open a socket should not cause
      # the failure of the test suite.
      1.upto(5).each do
        begin
          port = 1024 + rand(64510)
          Thread.new do
            FayeRails.server.listen(port)
          end
          break
        rescue
        end
      end
    end

    it "should receive messages after subscribe" do
      WidgetController.subscribe('/widgets/1') do |message|
        message.should == "Welcome to Cogswell Sprockets."
      end
      FayeRails.client.publish('/widgets/1', "Welcome to Cogswell Sprockets.")
    end
    
    it "should be able to subscribe to multiple channels" do
      2.upto(10).each do |i|
        WidgetController.subscribe("/widgets/#{i}") do |message|
          message.should == "Message number #{i}"
        end
        FayeRails.client.publish("/widgets/#{i}", "Message number #{i}")
      end
    end

    it "should be able to publish messages" do
      WidgetController.subscribe('/widgets/11') do |message|
        message.should == "Welcome to Cogswell Sprockets."
      end
      WidgetController.new.publish('/widgets/11', "Welcome to Cogswell Sprockets.")
    end

  end

end
