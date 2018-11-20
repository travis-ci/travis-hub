require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/addons/model/broadcast'
require 'travis/rollout'

module Travis
  module Addons
    module Handlers
      class Metrics < Base
        include Handlers::Task

        EVENTS = /job:(received|started|finished)/

        def handle?
          true
        end

        def handle
          name = :"handle_#{event.split(':').last}"
          send(name) if respond_to?(name, true)
        end

        private

          def payload
            object.id
          end

          def handle_received
            return unless object.queued_at && object.received_at
            events = %W(job.queue.wait_time job.queue.wait_time.#{queue})
            timer(events, object.received_at - object.queued_at)
          end

          def handle_started
            return unless object.received_at && object.started_at
            events = %W(job.boot.wait_time job.boot.wait_time.#{queue})
            timer(events, object.received_at - object.created_at)
          end

          def handle_finished
            return unless object.started_at && object.finished_at
            events = %W(job.duration job.duration.#{queue})
            timer(events, object.finished_at - object.started_at)
            return unless object.received_at
            events = %W(job.total_processing_time job.total_processing_time.#{queue})
            timer(events, object.finished_at - object.received_at)
          end

          def queue
            object.queue.to_s.gsub('.', '-')
          end

          def timer(events, duration)
            events.each do |event|
              Metriks.timer(event).update(duration)
            end
          end

          class EventHandler < Addons::Instrument
            def notify_completed
              publish
            end
          end
          EventHandler.attach_to(self)
      end
    end
  end
end
