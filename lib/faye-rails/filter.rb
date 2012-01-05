module FayeRails
  class Filter

    attr_accessor :server
    attr_reader   :channel

    def initialize(channel, direction=:any, block)
      @channel = channel
      raise ArgumentError, "Block cannot be nil" unless block
      if (direction == :in) || (direction == :any)
        @in_filter = DSL.new(block)
      end
      if (direction == :out) || (direction == :any)
        @out_filter = DSL.new(block)
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

    def incoming(message, callback)
      @in_filter.evaluate(message, channel, callback) if @in_filter
    end

    def outgoing(message, callback)
      @out_filter.evaluate(message, channel, callback) if @out_filter
    end

    def destroy
      if server
        server.remove_extension(self)
      end
    end

    class DSL

      attr_reader :channel, :message, :callback

      def initialize(block)
        raise ArgumentError, "Block cannot be nil" unless block
        @block = block
      end

      def evaluate(message, channel, callback)
        @channel = channel
        @message = message
        @callback = callback
        if message['channel'] == @channel
          instance_eval(&@block)
        else
          pass
        end
      end
      
      def pass
        return callback.call(message)
      end

      def modify(new_message)
        return callback.call(new_message)
      end

      def block(reason="Message blocked by filter")
        new_message = message
        new_message['error'] = reason
        return callback.call(new_message)
      end

      def drop
        return callback.call(nil)
      end

    end

  end
end
