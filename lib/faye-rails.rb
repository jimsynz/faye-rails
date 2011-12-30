require 'faye-rails/version'

module FayeRails
  ROOT = File.expand_path(File.dirname(__FILE__))

  class Engine < Rails::Engine
  end

  autoload :Controller,     File.join(ROOT, 'faye-rails', 'controller')

  def self.server
    @server
  end

  def self.server=(x)
    @server=x
  end

  def self.client
    server && server.get_client
  end
  
end
