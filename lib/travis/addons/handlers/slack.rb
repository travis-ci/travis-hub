require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Slack < Base
        include Handlers::Task

        EVENTS = 'build:finished'

        def handle?
          enabled?(:slack) && targets.any?(&:present?) && config.send_on?(:slack, action)
        end

        def handle
          targets.each do |target|
            run_task(:slack, payload, targets: target)
          end
        end

        def targets
          @targets ||= config.values(:slack, :rooms)
        end

        class Instrument < Addons::Instrument
          def notify_completed
            handler.targets.each do |target|
              publish(targets: target)
            end
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end
