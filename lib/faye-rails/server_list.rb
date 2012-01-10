class ServerList < Array
  def at(index)
    if index.is_a? String
      select do |server|
        server.endpoint == index
      end
    else
      super
    end
  end

  def <<(server)
    if at(server.endpoint).size == 0
      super
    else
      raise ArgumentError, "Server at mount point #{server.endpoint} is already present."
    end
  end
  alias push <<

  def clear!
    self.each do |server|
      server.stop
    end
    clear
  end
end

