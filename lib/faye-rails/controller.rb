module FayeRails
  class Controller
    autoload :Channel, File.join(FayeRails::ROOT, 'faye-rails', 'controller', 'channel')
    autoload :Monitor, File.join(FayeRails::ROOT, 'faye-rails', 'controller', 'monitor')
    autoload :Message, File.join(FayeRails::ROOT, 'faye-rails', 'controller', 'message')

    attr :channels, :model

    # Observe a model for a particular action.
    # where action is one of :initialize, :validation
    # :create, :update, :save, :destroy
    # when defaults to :after.
    def self.observe(model_klass, action, upon=:after, &block)
      if block && block.respond_to?(:call)
        model_klass.set_callback(action,upon) do |record|
          instance_eval do
            block.call record
          end
        end
      end
    end

    # Bind a number of events to a specific channel.
    def self.channel(channel, endpoint=nil, &block)
      channel = Channel.new(channel, endpoint)
      channel.instance_eval(&block)
      (@channels ||= []) << channel
    end

    def publish(channel, message, endpoint=nil)
      FayeRails.client(endpoint).publish(channel, message)
    end

  end
end
