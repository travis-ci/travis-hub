require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Hipchat < Notifiers
        EVENTS = 'build:finished'
        KEY = :hipchat

        class Notifier < Notifier
          def handle?
            enabled? && targets.present? && config.send_on?(:hipchat, action)
          end

          def handle
            run_task(:hipchat, payload, targets: targets, template: template, format: format)
          end

          def targets
            @targets ||= config.values(:rooms)
          end

          def format
            config.values(:format)
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
