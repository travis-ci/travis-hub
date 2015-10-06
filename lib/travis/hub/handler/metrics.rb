require 'travis/event/handler'
require 'travis/support/metrics'

module Travis
  module Hub
    module Handler
      class Metrics < Event::Handler
        register :metrics, self

        EVENTS = /job:(received|started|finished)/

        def handle?
          true
        end

        def handle
          name = :"handle_#{event.split(':').last}"
          send(name) if respond_to?(name, true)
        end

        private

          def handle_received
            return unless object.queued_at && object.received_at
            events = %W(job.queue.wait_time job.queue.wait_time.#{queue})
            meter(events, object.queued_at, object.received_at)
          end

          def handle_started
            return unless object.received_at && object.started_at
            events = %W(job.boot.wait_time job.boot.wait_time.#{queue})
            meter(events, object.created_at, object.received_at)
          end

          def handle_finished
            return unless object.started_at && object.finished_at
            events = %W(job.duration job.duration.#{queue})
            meter(events, object.started_at, object.finished_at)
          end

          def queue
            object.queue.to_s.gsub('.', '-')
          end

          def meter(events, started_at, finished_at)
            events.each do |event|
              Travis::Metrics.meter(event, started_at: started_at, finished_at: finished_at)
            end
          end
      end
    end
  end
end

