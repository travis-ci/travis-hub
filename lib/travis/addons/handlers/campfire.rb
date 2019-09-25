require 'travis/addons/handlers/base'
require 'travis/addons/handlers/notifier'

module Travis
  module Addons
    module Handlers
      class Campfire < Notifiers
        EVENTS = 'build:finished'
        KEY = :campfire

        class Notifier < Notifier
          def handle?
            !pull_request? && targets.present? && config.send_on?(:campfire, action)
          end

          def handle
            run_task(:campfire, payload, targets: targets, template: template)
          end

          def targets
            config.values(:rooms)
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
