require 'active_record'

module FayeRails
  class Controller

    # Define callbacks into any ORM model.
    module ObserverFactory

      # Create
      def self.define(klass, method_name, &block)
        # Make a name for the callback module
        
        klass_callbacks_name = "#{klass.name}Callbacks"

        # Load the callback module if exists
        unless (klass_callbacks = ObserverFactory.observer(klass_callbacks_name))
          # Define callback module if one does not exist
          klass_parent = klass.parent
          demodulized_callbacks_name = klass_callbacks_name.demodulize
          klass_callbacks = klass_parent.const_set(demodulized_callbacks_name, Module.new)
        end

        # Add the method to the observer
        klass_callbacks.instance_eval do
          define_method(method_name, &block)
        end

        # Bind model callback
        klass.send(method_name, klass_callbacks.extend(klass_callbacks))
      end

      def self.observer(module_name)
        ref = module_name.constantize
        return ref if ref.is_a?(Module)
        nil
      rescue
        nil
      end

    end
  end
end
