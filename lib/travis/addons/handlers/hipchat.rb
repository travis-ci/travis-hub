require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Hipchat < Base
        include Handlers::Task

        EVENTS = 'build:finished'

        def handle?
          enabled?(:hipchat) && targets.any?(&:present?) && config.send_on?(:hipchat, action)
        end

        def handle
          targets.each do |target|
            run_task(:hipchat, payload, targets: target)
          end
        end

        def targets
          @targets ||= config.values(:hipchat, :rooms)
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
