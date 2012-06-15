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

    def observe(model_klass, action, upon=:after, &block)
      if block && block.respond_to?(:call)
        self.class.register_instance_observer(self,model_klass,action,upon,block)
      end
    end

    def destroy
      self.class.unregister_instance_observers(self)
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

    private

    def self.register_instance_observer(instance, model_klass, action, upon, block)
      ((((((@action_list ||= {})[model_klass] ||= {})[action] ||= {})[upon] ||= {})[:instances] ||= {})[instance] ||= []) << block
      register_action(model_klass, action, upon) unless action_registered?(model_klass, action, upon)
    end

    def self.unregister_instance_observer(instance, block=nil)
      if block
        ((((((@action_list ||= {})[model_klass] ||= {})[action] ||= {})[upon] ||= {})[:instances] ||= {})[instance] ||= []).delete(block)
        if ((((((@action_list ||= {})[model_klass] ||= {})[action] ||= {})[upon] ||= {})[:instances] ||= {})[instance] ||= []).empty?
          (((((@action_list ||= {})[model_klass] ||= {})[action] ||= {})[upon] ||= {})[:instances] ||= {}).delete(instance)
        end
      else
        (((((@action_list ||= {})[model_klass] ||= {})[action] ||= {})[upon] ||= {})[:instances] ||= {}).delete(instance)
      end
    end

    def self.action_registered?(model_klass, action, upon)
      !!((((@action_list ||= {})[model_klass] ||= {})[action] ||= {})[upon] ||= {})[:registered]
    end

    def self.register_action(model_klass, action, upon)
      observe(model_klass, action, upon) do |record|
        (((((@action_list ||= {})[model_klass] ||= {})[action] ||= {})[upon] ||= {})[:instances] ||= {}).each do |instance, blocks|
          blocks.each do |block|
            instance.instance_eval do
              block.call(record)
            end
          end
        end
      end
      ((((@action_list ||= {})[model_klass] ||= {})[action] ||= {})[upon] ||= {})[:registered] = true
    end

  end
end
