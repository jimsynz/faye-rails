require 'active_record'

module FayeRails
  class Controller

    # Module creates ActiveRecord::Observer instances
    module ObserverFactory

      # Create
      def self.define(klass, method_name, &block)
        # Make a name for the observer
        klass_observer_name = "#{klass.to_s}Observer"

        # Load the observer if one exists
        klass_observer = ObserverFactory.observer(klass_observer_name)

        new_observer = klass_observer.nil?

        # Create a new observer if one does not exist
        klass_observer = Object.const_set(klass_observer_name, Class.new(ActiveRecord::Observer) do
          # TODO Work around this hack.
          # Have to define all of the available methods when creating the Observer class for the
          # first time. The methods can then be overriden by the observe DSL. However if they
          # are not first defined then they will not be registerable.
          [:before_validation, :after_validation, :before_save, :before_create, :after_create, :after_save, :after_commit].each do |arg|
            send :define_method, arg do |temp|
            end
          end
        end) if new_observer

        # Add the method to the observer
        klass_observer.instance_eval do
          define_method(method_name, &block)
        end

        # Add the observer if needed
        if new_observer
          ActiveRecord::Base.observers << klass_observer
        end

        ActiveRecord::Base.instantiate_observers
      end

      def self.observer(class_name)
        klass = Module.const_get(class_name)
        return klass if klass.is_a?(Class)
        return nil
      rescue
        return nil
      end

    end
  end
end
