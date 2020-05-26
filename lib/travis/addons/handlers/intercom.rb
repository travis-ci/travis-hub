require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Intercom < Notifiers
        EVENTS = 'build:created'
        KEY = :intercom

        class Notifier < Notifier
          def handle?
            true
          end

          def handle
            run_task(:intercom, payload)
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