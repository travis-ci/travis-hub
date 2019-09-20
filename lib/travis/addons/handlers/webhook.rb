require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Webhook < Base
        include Handlers::Task

        EVENTS = /build:(started|finished|canceled|errored)/

        def handle?
          targets.any?(&:present?) && config.send_on?(:webhooks, action)
        end

        def handle
          targets.each do |target|
            run_task(:webhook, payload, targets: target, token: request.token)
          end
        end

        def targets
          @targets ||= config.values(:webhooks, :urls)
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
