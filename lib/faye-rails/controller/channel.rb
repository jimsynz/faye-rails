module FayeRails
  class Controller
    class Channel

      attr_reader :channel, :endpoint

      def initialize(channel, endpoint=nil)
        @channel = channel
        @endpoint = endpoint
      end

      def client
        FayeRails.client(endpoint)
      end

      def publish(message)
        client.publish(channel, message)
      end

      def monitor(event, &block)
        raise ArgumentError, "Unknown event #{event.inspect}" unless [:subscribe,:unsubscribe,:publish].member? event

        FayeRails.server(endpoint).bind(event) do |*args|
          Monitor.new.tap do |m|
            m.client_id = args.shift
            m.channel = args.shift
            m.data = args.shift
            m.instance_eval(&block) if FayeRails::Matcher.match? channel, m.channel
          end
        end
      end

      def filter(direction=:any, &block)
        filter = FayeRails::Filter.new(channel, direction, block)
        server = FayeRails.server(endpoint)
        server.add_extension(filter)
        filter.server = server
        filter
      end

      def subscribe(&block)
        EM.schedule do
          FayeRails.client(endpoint).subscribe(channel) do |message|
            Message.new.tap do |m|
              m.message = message
              m.channel = channel
              m.instance_eval(&block)
            end
          end
        end
      end

      def unsubscribe
        EM.schedule do
          FayeRails.client(endpoint).unsubscribe(channel)
        end
      end

    end
  end
end
