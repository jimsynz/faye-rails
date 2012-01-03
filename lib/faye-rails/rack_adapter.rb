require 'faye'

module FayeRails
  class RackAdapter < ::Faye::RackAdapter

    attr_reader :server, :endpoint

    def initialize(app=nil, options=nil)
      super
      FayeRails.servers << self
    end

    def listen(port, ssl_options = nil)
      Thread.new do
        super
      end
    end

  end
end
