require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Campfire < Base
        include Handlers::Task

        EVENTS = 'build:finished'

        def handle?
          !pull_request? && targets.present? && config.send_on?(:campfire, action)
        end

        def handle
          run_task(:campfire, payload, targets: targets)
        end

        def targets
          config.values(:campfire, :rooms)
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
