require 'spec_helper'

describe FayeRails::Controller::ObserverFactory do
  context "create new observer" do
    before(:all) do
      Ryan = Class.new(ActiveRecord::Base)
      FayeRails::Controller::ObserverFactory.define(Ryan, :after_create) do
      end
      FayeRails::Controller::ObserverFactory.define(Ryan, :before_create) do
      end
    end

    it { FayeRails::Controller::ObserverFactory.observer("RyanObserver").should_not be_nil }
    it { FayeRails::Controller::ObserverFactory.observer("RyansObserver").should be_nil }

    context "should extend ActiveRecord::Observer" do
      it { RyanObserver.ancestors.should include(ActiveRecord::Observer) }
      it { RyanObserver.should respond_to :observe }
      it { RyanObserver.method_defined?(:observe).should be_false }
    end

    context "register callbacks" do
      it { RyanObserver.method_defined?(:before_validation).should be_false }
      it { RyanObserver.method_defined?(:after_validation).should be_false }
      it { RyanObserver.method_defined?(:before_save).should be_false }
      it { RyanObserver.method_defined?(:before_create).should be_true }
      it { RyanObserver.method_defined?(:after_create).should be_true }
      it { RyanObserver.method_defined?(:after_save).should be_false }
      it { RyanObserver.method_defined?(:after_commit).should be_false }
    end

    context "registered with ActiveRecord" do
      it { ActiveRecord::Base.observers.should include(RyanObserver) }
    end
  end
end
