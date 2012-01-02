module FayeRails
  class Controller

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

    # Pass in the name of a channel to subscribe to
    # and anytime 
    def self.subscribe(channel, endpoint=nil, &block)
      if block && block.respond_to?(:call)
        FayeRails.client(endpoint).subscribe(channel) do |message|
          instance_eval do
            block.call message
          end
        end
        (@channels ||= []) << channel
      end
    end

    def publish(channel, message, endpoint=nil)
      FayeRails.client(endpoint).publish(channel, message)
    end

  end
end
