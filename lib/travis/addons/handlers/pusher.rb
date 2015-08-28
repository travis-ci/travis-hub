require 'travis/addons/handlers/generic'
require 'travis/addons/serializer/pusher/build'
require 'travis/addons/serializer/pusher/job'

module Travis
  module Addons
    module Handlers
      class Pusher < Event::Handler
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
          run_task(QUEUE, payload, event: event)
        end

        def payload
          Serializer::Pusher.const_get(object_type.camelize).new(object, params: data).data
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish if Instruments.publish?(handler.event)
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end
