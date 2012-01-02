require 'faye'

module FayeRails
  class RackAdapter < ::Faye::RackAdapter

    ERROR_WEBSOCKETS_DISABLED_RESPONSE = [400, { :content_type => 'text/plain', :content_length => 30 }, ["Error: WebSockets not enabled."]].freeze

    attr_reader :server, :endpoint

    def initialize(app=nil, options=nil)
      super
      @enable_websockets = @options.delete(:enable_websockets)
      FayeRails.servers << self
    end

    def call(env)
      if @enable_websockets && env['HTTP_UPGRADE']
        ws = ::Faye::WebSocket.new(env)
        ws.onmessage = lambda do |event|
          ws.send(event.data)
        end
        ws.onclose = lambda do |event|
          ws = nil
        end
        ASYNC_RESPONSE
      elsif env['HTTP_UPGRADE']
        ERROR_WEBSOCKETS_DISABLED_RESPONSE
      else
        super
      end
    end

  end
end
