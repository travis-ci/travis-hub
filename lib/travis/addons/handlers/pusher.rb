require 'travis/addons/handlers/base'
require 'travis/addons/serializer/pusher/build'
require 'travis/addons/serializer/pusher/job'
require 'travis/sidekiq'

module Travis
  module Addons
    module Handlers
      class Pusher < Base
        EVENTS = [
          /^build:(created|received|started|finished|canceled|restarted)/,
          /^job:(created|received|started|finished|canceled|restarted)/
        ]
        QUEUE = :'pusher-live'

        attr_reader :channels

        def handle?
          true
        end

        def handle
          run_task 'pusher-live', payload, event: event
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
