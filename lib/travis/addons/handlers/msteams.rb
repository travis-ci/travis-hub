require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      # MS Teams notification handler that sends Adaptive Cards
      # Triggers when builds finish
      class Msteams < Notifiers
        EVENTS = 'build:finished'
        KEY = :msteams

        class Notifier < Notifier
          def handle?
            enabled? && targets.present? && config.send_on?(:msteams, action)
          end

          def handle
            run_task(:msteams, payload, targets:, token: request.token)
          end

          def payload
            @payload ||= Serializer::Tasks::Msteams.new(object).data
          end

          def targets
            @targets ||= config.values(:rooms)
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
