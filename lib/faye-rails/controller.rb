module FayeRails
  class Controller
    autoload :Channel, File.join(FayeRails::ROOT, 'faye-rails', 'controller', 'channel')
    autoload :Monitor, File.join(FayeRails::ROOT, 'faye-rails', 'controller', 'monitor')
    autoload :Message, File.join(FayeRails::ROOT, 'faye-rails', 'controller', 'message')
    autoload :ObserverFactory, File.join(FayeRails::ROOT, 'faye-rails', 'controller', 'observer_factory')

    attr :channels, :model

    # Observe a model for any of the ActiveRecord::Callbacks
    # as of v3.2.6 they are:
    # before_validation
    # after_validation
    # before_save
    # before_create
    # after_create
    # after_save
    # after_commit
    # http://api.rubyonrails.org/classes/ActiveRecord/Callbacks.html
    # action defaults to after_create
    def self.observe(model_klass, action = :after_create, &block)
      # Dynamically create a new observe class
      ObserverFactory.define(model_klass, action, &block)
    end

    def observe(model_klass, action = :after_create, &block)
      # Dynamically create a new observe class
      ObserverFactory.define(model_klass, action, &block)
    end

    # Bind a number of events to a specific channel.
    def self.channel(channel, endpoint=nil, &block)
      channel = Channel.new(channel, endpoint)
      channel.instance_eval(&block)
      (@channels ||= []) << channel
    end

    def channel(channel, endpoint=nil, &block)
      channel = Channel.new(channel, endpoint)
      channel.instance_eval(&block)
      (@channels ||= []) << channel
    end

    def self.publish(channel, message, endpoint=nil)
      FayeRails.client(endpoint).publish(channel, message)
    end

    def publish(channel, message, endpoint=nil)
      self.class.publish(channel, message, endpoint)
    end

  end
end
