require 'travis/addons/handlers/generic'
require 'travis/addons/serializer/pusher/build'
require 'travis/addons/serializer/pusher/job'

module Travis
  module Addons
    module Handlers
      class Pusher < Event::Handler
        include Helpers

        EVENTS = [
          /^build:(created|received|started|finished|canceled)/,
          /^job:(created|received|started|finished|canceled)/
        ]
        QUEUE = :'pusher-live'

        attr_reader :channels

        def handle?
          true
        end

        def handle
          # TODO change live to allow using an alternative worker signature
          ::Sidekiq::Client.push(
            'queue'  => QUEUE,
            'class'  => 'Travis::Async::Sidekiq::Worker',
            'method' => 'perform',
            'args'   => [nil, nil, nil, payload, event: event],
            'retry'  => true
          )
        end

        def payload
          Serializer::Pusher.const_get(object_type.camelize).new(object, params: data).data
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end
