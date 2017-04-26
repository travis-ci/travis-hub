require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Slack < Base
        include Handlers::Task

        EVENTS = 'build:finished'

        def handle?
          enabled?(:slack) && targets.present? && config.send_on?(:slack, action)
        end

        def handle
          run_task(:slack, payload, targets: targets)
        end

        def targets
          @targets ||= config.values(:slack, :rooms)
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

