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
            enabled? && targets.present? && config.send_on?(:slack, action)
          end

          def handle
            run_task(:slack, payload, targets:, template:)
          end

          def targets
            Addons.logger.info "config inspect: #{config.inspect}"
            @targets ||= config.values(:rooms)
            if @targets.empty?
              Addons.logger.info "No Slack rooms found for #{object.repository.slug}"
            else
              Addons.logger.info "Sending Slack notification to rooms: #{@targets.join(', ')}"
            end
            @targets
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
