require 'faye'

module FayeRails
  class RackAdapter < ::Faye::RackAdapter

    attr_reader :server, :endpoint

    def initialize(app=nil, options=nil)
      super
      FayeRails.servers << self
    end

    def listen(port, ssl_options = nil)
      if defined? ::Rails
        Faye.ensure_reactor_running!
        super
      else
        super
      end
    end

    def routing_extension
      if @routing_extension
        @routing_extension
      else
        @routing_extension = RoutingExtension.new
        server.add_extension(@routing_extension)
      end
    end

    def map(opts)
      routing_extension
      if opts.is_a? Hash
        opts.each do |channel, controller|
          if channel.is_a? String
            routing_extension.map(channel, controller)
          elsif channel == :default
            if controller == :block
              routing_extension.block_unknown_channels!
            elsif controller == :drop
              routing_extension.drop_unknown_channels!
            elsif controller == :allow
              routing_extension.allow_unknown_channels!
            end
          end
        end
      end
    end

    class RoutingExtension < Filter

      def initialize
        @default = :allow
        @mappings = {}
        super nil, :any do
          if message['channel'] == '/meta/subscribe'
            take_action_for message['subscription']
          elsif message['channel'] == '/meta/unsubscribe'
            take_action_for message['subscription']
          elsif message['channel'][0..5] == '/meta/'
            pass
          elsif message['channel'][0..8] == '/service/'
            pass
          else
            take_action_for message['channel']
          end
        end
      end

      def block_unknown_channels!
        @default = :block
      end

      def drop_unknown_channels!
        @default = :drop
      end

      def allow_unknown_channels!
        @default = :allow
      end

      def take_action_for(test)
        if @mappings.keys.member? test
          pass
        elsif @default == :block
          block "Permission denied."
        elsif @default == :drop
          drop
        elsif @default == :allow
          allow
        else
          drop
        end
      end

    end

  end
end
