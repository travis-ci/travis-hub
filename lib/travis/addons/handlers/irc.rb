require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Irc < Base
        include Handlers::Task

        EVENTS = 'build:finished'

        def handle?
          !pull_request? && channels.present? && config.send_on?(:irc, action)
        end

        def handle
          run_task(:irc, payload, channels: channels)
        end

        def channels
          @channels ||= config.values(:irc, :channels)
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

