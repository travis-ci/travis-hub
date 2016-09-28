require 'travis/addons/handlers/base'
require 'travis/sidekiq'

module Travis
  module Addons
    module Handlers
      class Scheduler < Base
        EVENTS = ['job:finished', 'job:canceled', 'job:restarted']

        def handle?
          true
        end

        def handle
          Travis::Sidekiq.scheduler(event, id: object.id)
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
