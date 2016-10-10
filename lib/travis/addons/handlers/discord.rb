require 'travis/addons/handlers/base'

module Travis
  module Addons
    module Handlers
      class Discord < Base
        EVENTS = 'build:finished'

        def handle?
          enabled?(:discord) && targets.present? && config.send_on?(:discord, action)
        end

        def handle
          run_task(:discord, payload, targets: targets)
        end

        def targets
          @targets ||= config.values(:discord, :channels)
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

