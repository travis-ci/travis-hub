require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Flowdock < Notifiers
        EVENTS = 'build:finished'
        KEY = :flowdock

        class Notifier < Notifier
          def handle?
            !pull_request? && targets.present? && config.send_on?(:flowdock, action)
          end

          def handle
            run_task(:flowdock, payload, targets: targets)
          end

          def targets
            @targets ||= config.values(:rooms)
          end

          class Instrument < Addons::Instrument
            def notify_completed
              publish(targets: handler.targets)
            end
          end
          Instrument.attach_to(self)
        end
      end
    end
  end
end
