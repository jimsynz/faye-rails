if defined? ActionDispatch::Routing

  module ActionDispatch::Routing
    class Mapper

      def faye_server(mount_path, options={}, &block)

        defaults = {
          :mount => mount_path||'/faye',
          :timeout => 25,
          :extensions => nil,
          :engine => nil,
          :ping => nil,
          :server => 'thin'
        }

        unknown_options = options.keys - defaults.keys
        if unknown_options.one?
          raise ArgumentError, "Unknown option: #{unknown_options.first}."
        elsif unknown_options.any?
          raise ArgumentError, "Unknown options: #{unknown_options * ", "}."
        end

        options = defaults.merge(options)

        Faye::WebSocket.load_adapter(options.delete(:server))

        adapter = FayeRails::RackAdapter.new(options)
        adapter.instance_eval(&block) if block.respond_to? :call

        match options[:mount] => adapter, via: :all

      end

    end
  end

end

if defined? Rails::Application::RoutesReloader

  class Rails::Application::RoutesReloader

    def clear_with_faye_servers!
      FayeRails.servers.clear!
      clear_without_faye_servers!
    end

    alias_method_chain :clear!, :faye_servers

  end

end
