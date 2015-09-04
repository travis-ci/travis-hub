require 'metriks'
require 'travis/support/instrumentation'
require 'travis/hub/model/job'
require 'travis/hub/services/workers'
require 'travis/hub/support/lock'

module Travis
  module Services
    class UpdateJob
      extend Instrumentation

      EVENTS = [:receive, :start, :finish, :cancel, :reset]

      attr_reader :event, :data

      def initialize(params)
        @event = params[:event].try(:to_sym)
        @data  = params[:data].symbolize_keys
      end

      def run
        validate
        update_job
        Workers.new.cancel(job) if job.canceled? && event != :reset
      end
      instrument :run

      private

        def update_job
          exclusive do
            job.send(:"#{event}!", data)
          end
        end

        def job
          @job ||= Job.find(data[:id])
        end

        def validate
          EVENTS.include?(event) || fail(ArgumentError, "Unknown event: #{event}, data: #{data}")
        end

        def exclusive(&block)
          Hub::Support::Lock.exclusive("hub:update_job:#{job.id}", Hub.config.lock, &block)
        end

        class Instrument < Instrumentation::Instrument
          def run_completed
            publish(
              msg: "event: #{target.event} for <Job id=#{target.data[:id]}> data=#{target.data.inspect}",
              job_id: target.data[:id],
              event: target.event,
              data: target.data
            )
          end
        end
        Instrument.attach_to(self)
      end
  end
end

