module FayeRails
  class Middleware

    DEFAULTS = {
      :mount => '/faye',
      :timeout => 25,
      :extensions => nil,
      :engine => nil,
      :ping => nil,
      :server => 'thin'
    }

    def initialize(app, options={}, &block)
      @app = app

      unknown_options = options.keys - DEFAULTS.keys
      if unknown_options.one?
        raise ArgumentError, "Unknown option: #{unknown_options.first}."
      elsif unknown_options.any?
        raise ArgumentError, "Unknown options: #{unknown_options * ", "}."
      end

      options = DEFAULTS.merge(options)
      Faye::WebSocket.load_adapter(options.delete(:server))

      @adapter = FayeRails::RackAdapter.new(@app, options)
      @adapter.instance_eval(&block) if block.respond_to? :call
    end

    def call(env)
      @adapter.call(env)
    end
  end
end