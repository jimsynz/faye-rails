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

    # Rudimentary routing support for channels to controllers.
    #
    # @param opts
    #   a Hash of mappings either string keys (channel globs)
    #   mapping to controller constants eg:
    #
    #     '/widgets/**' => WidgetsController
    #
    #   or you can set the behaviour for unknown channels:
    #
    #     :default => :block
    #
    #   :default can be set to :allow, :drop or :block.
    #   if :drop is chosen then messages to unknown channels
    #   will be silently dropped, whereas if you choose
    #   :block then the message will be returned with the
    #   error "Permission denied."
    def map(opts)
      if opts.is_a? Hash
        opts.each do |channel, controller|
          if channel.is_a? String
            if FayeRails::Matcher.match? '/**', channel
              routing_extension.map(channel, controller)
            else
              raise ArgumentError, "Invalid channel: #{channel}"
            end
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

    # Adds a very simple extension to the server causing
    # it to log all messages in and out to Rails.logger.debug.
    def debug_messages
      add_extension(DebugMessagesExtension.new)
    end

    private

    def routing_extension
      if @routing_extension
        @routing_extension
      else
        @routing_extension = RoutingExtension.new
        add_extension(@routing_extension)
        @routing_extension
      end
    end

    class DebugMessagesExtension

      def debug(*args)
        if defined? ::Rails
          Rails.logger.debug *args
        else
          puts *args
        end
      end

      def incoming(m,c)
        debug " **  IN: #{m.inspect}"
        c.call(m)
      end

      def outgoing(m,c)
        debug " ** OUT: #{m.inspect}"
        c.call(m)
      end
    end

    class RoutingExtension

      def initialize
        @default = :allow
        @mappings = {}
      end

      def incoming(message, callback)
        if message['channel'] == '/meta/subscribe'
          take_action_for message, callback, message['subscription']
        elsif message['channel'] == '/meta/unsubscribe'
          take_action_for message, callback, message['subscription']
        elsif FayeRails::Matcher.match? '/meta/*', message['channel']
          callback.call(message)
        elsif FayeRails::Matcher.match? '/service/**', message['channel']
          callback.call(message)
        else
          take_action_for message, callback, message['channel']
        end
      end

      def map(channel, controller)
        if FayeRails::Matcher.match? '/**', channel
          (@mappings[channel] ||= []) << controller
        else
          raise ArgumentError, "Invalid channel name: #{channel}"
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

      def take_action_for(message, callback, test='')
        if @mappings.keys.select { |glob| FayeRails::Matcher.match? glob, test }.size > 0
          callback.call(message)
        elsif @default == :block
          message['error'] = "Permission denied"
          callback.call(message)
        elsif @default == :drop
          callback.call(nil)
        elsif @default == :allow
          callback.call(message)
        else
          callback.call(nil)
        end
      end

    end

  end
end
