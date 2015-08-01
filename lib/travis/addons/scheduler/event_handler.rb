require 'sidekiq'
require 'travis/event/handler'
require 'travis/notification/instrument/event_handler'
require 'travis/task'

module Travis
  module Addons
    module Scheduler
      class EventHandler < Event::Handler
        EVENTS = [
          /^job:test:(created|finished|canceled)/
        ]

        def handle?
          true
        end

        def handle
          ::Sidekiq::Client.push(
            'queue' => :scheduler,
            'retry' => 3,
            'class' => 'Travis::Scheduler::Worker::Receive',
            'args'  => [event, id: object.id]
          )
        end

        def event
          super.sub('test:', '')
        end

        private

          class Instrument < Notification::Instrument::EventHandler
            def notify_completed
              publish(event: handler.event)
            end
          end.attach_to(self)
      end
    end
  end
end

