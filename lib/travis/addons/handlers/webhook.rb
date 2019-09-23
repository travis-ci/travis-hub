require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Webhook < Notifiers
        EVENTS = /build:(started|finished|canceled|errored)/
        KEY = :webhooks

        class Notifier < Notifier
          def handle?
            targets.present? && config.send_on?(:webhooks, action)
          end

          def handle
            run_task(:webhook, payload, targets: targets, token: request.token)
          end

          def targets
            @targets ||= config.values(:urls)
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
