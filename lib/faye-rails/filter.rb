module FayeRails
  class Filter

    attr_accessor :server
    attr_reader   :channel
    attr_writer   :logger

    # Create a new FayeRails::Filter which can be passed to
    # Faye::RackAdapter#add_extension.
    #
    # @param channel
    #   Optional channel name to limit messages to.
    # @param direction
    #   :in, :out or :any.
    # @param block
    #   A proc object to be called when filtering messages.
    def initialize(channel='/**', direction=:any, block)
      @channel = channel
      @block = block
      raise ArgumentError, "Block cannot be nil" unless block
      if (direction == :in) || (direction == :any)
        @in_filter = DSL
      end
      if (direction == :out) || (direction == :any)
        @out_filter = DSL
      end
    end

    def respond_to?(method)
      if (method == :incoming) 
        !!@in_filter
      elsif (method == :outgoing)
        !!@out_filter
      else
        super
      end
    end

    def logger
      if defined?(::Rails)
        @logger ||= Rails.logger
      end
    end

    def incoming(message, callback)
      @in_filter.new(@block, message, channel, callback, :incoming) if @in_filter
    end


    def outgoing(message, callback)
      @out_filter.new(@block, message, channel, callback, :outgoing) if @out_filter
    end

    def destroy
      if server
        server.remove_extension(self)
      end
    end

    class DSL

      # A small wrapper class around filter blocks to
      # add some sugar to ease filter (Faye extension)
      # creation.

      attr_reader :channel, :message, :callback, :original_message, :direction

      # Called by FayeRails::Filter when Faye passes
      # messages in for evaluation.
      # @param block
      #   The block you wish to execute whenever a matching
      #   message is recieved.
      # @param channel
      #  optional: if present then the block will only be called for matching messages, otherwise all messages will be passed.
      def initialize(block, message, channel='/**', callback, direction)
        raise ArgumentError, "Block cannot be nil" unless block
        @channel = channel
        @original_message = message.dup
        @message = message
        @callback = callback
        @direction = direction

        if channel_matches?(@channel, @original_message['channel']) ||
          (subscribing? && subscription?(@channel)) ||
          (unsubscribing? && subscription?(@channel))
          instance_eval(&block)
        else
          pass
        end
      end

      # Easier than testing message['channel'] every time
      def subscribing?
        message['channel'] == '/meta/subscribe'
      end

      def unsubscribing?
        message['channel'] == '/meta/unsubscribe'
      end

      def meta?
        message['channel'][0..5] == '/meta/'
      end

      def service?
        message['channel'][0..8] == '/service/'
      end

      def incoming?
        direction == :incoming
      end
      alias in? incoming?

      def outgoing?
        direction == :outgoing
      end
      alias out? outgoing?

      def data
        message['data']
      end

      def data?
        !!data
      end

      def client_id?(x=nil)
        if !!x
          message['client_id'] == x
        else
          !!message['client_id']
        end
      end

      def channel_matches?(glob,test)
        FayeRails::Matcher.match? glob, test
      end

      def subscription?(channel)
        message['subscription'] && channel_matches?(channel, message['subscription'])
      end
      
      # Syntactic sugar around callback.call which passes
      # back the original message unmodified.
      def pass
        callback.call(original_message)
      end

      # Syntactic sugar around callback.call which passes
      # the passed argument back to Faye in place of the 
      # original message.
      # @param new_message
      #   Replacement message to send back to Faye.
      def modify(new_message)
        callback.call(new_message)
      end

      # Syntactic sugar around callback.call which adds
      # an error message to the message and passes it back
      # to Faye, which will send back a rejection message to
      # the sending client.
      # @param reason
      #   The error message to be sent back to the client.
      def block(reason="Message blocked by filter")
        new_message = message
        new_message['error'] = reason
        callback.call(new_message)
      end

      # Syntactic sugar around callback.call which returns
      # nil to Faye - effectively dropping the message.
      def drop
        callback.call(nil)
      end

    end

  end
end
