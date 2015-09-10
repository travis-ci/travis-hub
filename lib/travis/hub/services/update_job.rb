require 'metriks'
require 'travis/support/instrumentation'
require 'travis/hub/model/job'
require 'travis/hub/services/workers'
require 'travis/hub/support/lock'

module Travis
  module Hub
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
          exclusive do
            validate
            update_job
            Workers.new.cancel(job) if job.canceled? && event != :reset
          end
        end
        instrument :run

        private

          def update_job
            job.send(:"#{event}!", data)
          rescue Exception => e
            puts e.message, e.backtrace
          end

          def job
            @job ||= Job.find(data[:id])
          end

          def validate
            EVENTS.include?(event) || fail(ArgumentError, "Unknown event: #{event}, data: #{data}")
          end

          def exclusive(&block)
            # # TODO use the build_id here!
            Travis::Support::Lock.exclusive("hub:update_job:#{data[:id]}", Hub.config.lock, &block)
            # job.with_lock(lock: true, &block)
          rescue Timeout::Error => e
            Hub.logger.info("Timeout processing an update for job #{data[:id]}. Could not obtain a lock?")
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
end
