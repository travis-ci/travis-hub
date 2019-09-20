require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Flowdock < Base
        include Handlers::Task

        EVENTS = 'build:finished'

        def handle?
          !pull_request? && targets.any?(&:present?) && config.send_on?(:flowdock, action)
        end

        def handle
          targets.each do |target|
            run_task(:flowdock, payload, targets: target)
          end
        end

        def targets
          @targets ||= config.values(:flowdock, :rooms)
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
