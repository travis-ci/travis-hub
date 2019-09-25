require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Irc < Notifiers
        EVENTS = 'build:finished'
        KEY = :irc

        class Notifier < Notifier
          def handle?
            !pull_request? && channels.present? && config.send_on?(:irc, action)
          end

          def handle
            run_task(:irc, payload, channels: channels, template: template)
          end

          def channels
            @channels ||= config.values(:channels)
          end

          class Instrument < Addons::Instrument
            def notify_completed
              publish(channels: handler.channels)
            end
          end
          Instrument.attach_to(self)
        end
      end
    end
  end
end
