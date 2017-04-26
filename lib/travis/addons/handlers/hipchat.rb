require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Hipchat < Base
        include Handlers::Task

        EVENTS = 'build:finished'

        def handle?
          enabled?(:hipchat) && targets.present? && config.send_on?(:hipchat, action)
        end

        def handle
          run_task(:hipchat, payload, targets: targets)
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
