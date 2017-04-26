require 'travis/addons/handlers/base'
require 'travis/sidekiq'

module Travis
  module Addons
    module Handlers
      class Scheduler < Base
        EVENTS = ['job:created', 'job:finished', 'job:canceled', 'job:restarted']

        def handle?
          true
        end

        def handle
          check_queueuable
          Travis::Sidekiq.scheduler(event, payload)
        end

        def check_queueuable
          expected = action == :created ? true : false
          queueable = !!object.reload.queueable
          level = expected == queueable ? :info : :warn
          msg = "[notify-scheduler] job=#{object.id} event=#{event} state=#{object.state} queueable=#{!!queueable} (#{'NOT ' if level == :warn}expected)"
          Travis::Addons.logger.send(level, msg)
        end

        def payload
          { id: object.id }
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end
