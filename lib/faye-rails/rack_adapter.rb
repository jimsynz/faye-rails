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

  end
end
