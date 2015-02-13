require 'faye'
require 'faye-rails/version'
require 'faye-rails/middleware'
require 'faye-rails/server_list'

module FayeRails
  ROOT = File.expand_path(File.dirname(__FILE__))

  if defined? ::Rails
    class Engine < ::Rails::Engine
    end
  end

  autoload :Controller,        File.join(ROOT, 'faye-rails', 'controller')
  autoload :RackAdapter,       File.join(ROOT, 'faye-rails', 'rack_adapter')
  autoload :Filter,            File.join(ROOT, 'faye-rails', 'filter')
  autoload :Matcher,           File.join(ROOT, 'faye-rails', 'matcher')

  def self.servers
    @servers ||= ServerList.new
  end

  def self.server(where=nil)
    if where
      servers.at(where).first
    else
      servers.first
    end
  end

  def self.clients
    servers.map(&:get_client)
  end

  def self.client(where=nil)
    if where
      servers.at(where).first.get_client
    else
      servers.first.get_client
    end
  end

end
