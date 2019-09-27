require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Slack < Notifiers
        EVENTS = 'build:finished'
        KEY = :slack

        class Notifier < Notifier
          def handle?
            Addons.logger.info("config=#{config.to_s}")
            Addons.logger.info("on_pull_request?=#{on_pull_request?.to_s}")
            enabled? && targets.present? && config.send_on?(:slack, action)
          end

          def handle
            run_task(:slack, payload, targets: targets, template: template)
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
