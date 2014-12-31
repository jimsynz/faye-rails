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

      if Rails.application.config.middleware.include? Rack::Lock
        message = <<-EOF

WARNING: You have the Rack::Lock middlware enabled.

faye-rails can't work when Rack::Lock is enabled, as it will cause
a deadlock on every request.

Please add:

    config.middleware.delete Rack::Lock

to your application config in application.rb

        EOF
        Rails.logger.fatal message
        $stdout.puts message
        exit 1
      end

      unknown_options = options.keys - DEFAULTS.keys
      if unknown_options.one?
        raise ArgumentError, "Unknown option: #{unknown_options.first}."
      elsif unknown_options.any?
        raise ArgumentError, "Unknown options: #{unknown_options * ", "}."
      end

      options = DEFAULTS.merge(options)
      server = options.delete(:server)
      Faye::WebSocket.load_adapter(server) if server && server != 'passenger'

      @adapter = FayeRails::RackAdapter.new(@app, options)
      @adapter.instance_eval(&block) if block.respond_to? :call
    end

    def call(env)
      @adapter.call(env)
    end
  end
end
