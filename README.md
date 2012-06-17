# faye-rails [![Build Status](https://secure.travis-ci.org/RLovelett/faye-rails.png)](http://travis-ci.org/RLovelett/faye-rails)

faye-rails is a Ruby gem which handles embedding Faye's rack-based server into the rails stack and providing it with access to controllers and views based on bindings and observers.

# Embedded server

Due to the limitations of most Rack-based web servers available Faye can only be run on Thin, however if you are using thin, then you can add as many Faye servers as you want to the Rails router like so:

    App::Application.routes.draw do
      faye_server '/faye', :timeout => 25
    end

You can also pass a block to `faye_server` which will be executed in the context of the Faye server, thus you can call any methods on `Faye::RackAdapter` from within the block:

    App::Application.routes.draw do
      faye_server '/faye', :timeout => 25 do
        class MockExtension
          def incoming(message, callback)
            callback.call(message)
          end
        end
        add_extension(MockExtension.new)
      end
    end

If you really want to, you can ask Faye to start it's own listening Thin server on an arbitrary port:

    App::Application.routes.draw do
      faye_server '/faye', :timeout => 25 do
        listen(9292)
      end
    end

You can also do some rudimentary routing using the map method:

    App::Application.routes.draw do
      faye_server '/faye', :timeout => 25 do
        map '/widgets/**' => WidgetsController
        map :default => :block
      end
    end

You can find more details on the #map method in the [rdoc](http://rubydoc.info/github/jamesotron/faye-rails/master/FayeRails/RackAdapter)

# Controller

faye-rails includes a controller for handling the binding between model events and channels with it's own DSL for managing channel-based events.

    class WidgetController < FayeRails::Controller
    end

## Model observers

You can subscribe to changes in models using the controller's observer DSL:

    class WidgetController < FayeRails::Controller
      observe Widget, :create do |new_widget|
        publish('/widgets', new_widget.attributes)
      end
    end

See the [rdoc](http://rubydoc.info/github/jamesotron/faye-rails/master/FayeRails/Controller.observe) for more information.

## Channel DSL

The controller DSL elegantly wraps channel-based aspects of the Faye API so that you can easily group code based on specific channels.

### Monitoring

You can make use of Faye's [monitoring API](http://faye.jcoglan.com/ruby/monitoring.html) by adding calls to `monitor` within the channel block. You are able to monitor `:subscribe`, `:unsubscribe` and `:publish` events. Blocks are executed within the context of a `FayeRails::Controller::Monitor` instance which will give you access to `#client_id`, `#channel` and `#data` (`#data` only having a value on `:publish` events).

    class WidgetController < FayeRails::Controller
      channel '/widgets' do
        monitor :subscribe do
          puts "Client #{client_id} subscribed to #{channel}."
        end
        monitor :unsubscribe do
          puts "Client #{client_id} unsubscribed from #{channel}."
        end
        monitor :publish do
          puts "Client #{client_id} published #{data.inspect} to #{channel}."
        end
      end
    end

### Filtering

You can quickly and easily filter incoming and outgoing messages for your specific channel using the controller's filter API, which wraps Faye's [extensions API](http://faye.jcoglan.com/ruby/extensions.html) in a concise and channel-specific way.

    class WidgetController < FayeRails::Controller
      channel '/widgets' do
        filter :in do
          puts "Inbound message #{message}."
          pass
        end
      end
    end

You can add filters for `:in`, `:out` and `:any`, which will allow you to filter messages entering the server, exiting the server or both. The block passed to the `filter` is executed in the context of a `FayeRails::Filter::DSL` instance, which gives you access to the `#message` method, which contains the entire message payload from the client (including meta information you wouldn't see other ways). You also have access to the `#pass`, `#modify`, `#block` and `#drop` methods which are sugar around Faye's callback system - which is accessible via the `#callback` method if you want to do it that way. Check out the [FayeRails::Filter::DSL rdoc](http://rubydoc.info/github/jamesotron/faye-rails/master/FayeRails/Filter/DSL) for more information.  Please note that all filters must call `callback.call` either via the sugar methods or directly to ensure that requests are not lost (not to mention potential memory leaks).

### Subscribing

You can easily subscribe to a channel using the 'subscribe' method inside your channel block, like so:

    class WidgetController < FayeRails::Controller
      channel '/widgets' do
        subscribe do
          puts "Received on channel #{channel}: #{message.inspect}"
        end
      end
    end

# Thanks.

Thanks to James Coglan for the excellent Faye Bayeux implementetation and great support for Faye users.
