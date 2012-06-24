module Within 

  def within(timeout=5.seconds, &block)
    @timeout = timeout.to_i
    raise ArgumentError "Timeout must be greater than zero seconds" unless @timeout > 0
    @block = block
    raise ArgumentError "Proc doesn't respond to #call" unless @block.respond_to? :call
    raise RuntimeError "Event Machine reactor is not running" unless EM.reactor_running?

    Fiber.new do
      this_fiber = Fiber.current
      EM.add_timer(@timeout) do
        if this_fiber.alive?
          raise RuntimeError "Timeout waiting for test to finish."
        end
      end
      @block.call(this_fiber.method(:resume), *args)
    end.resume
  end
end
