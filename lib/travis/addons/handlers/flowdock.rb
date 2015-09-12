require 'travis/addons/handlers/base'

module Travis
  module Addons
    module Handlers
      class Flowdock < Base
        EVENTS = 'build:finished'

        def handle?
          !pull_request? && targets.present? && config.send_on?(:flowdock, action)
        end

        def handle
          run_task(:flowdock, payload, targets: targets)
        end

        def targets
          @targets ||= config.values(:flowdock, :rooms)
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish(:targets => handler.targets)
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end

