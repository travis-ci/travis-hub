require 'travis/addons/handlers/base'

module Travis
  module Addons
    module Handlers
      class Sqwiggle < Base
        EVENTS = 'build:finished'

        def handle?
          !pull_request? && targets.present? && config.send_on?(:sqwiggle, action)
        end

        def handle
          run_task(:sqwiggle, payload, targets: targets)
        end

        def targets
          @targets ||= config.values(:sqwiggle, :rooms)
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

