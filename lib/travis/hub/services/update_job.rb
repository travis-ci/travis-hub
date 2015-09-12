require 'metriks'
require 'travis/support/instrumentation'
require 'travis/hub/helpers/locking'
require 'travis/hub/model/job'
require 'travis/hub/services/workers'
require 'travis/hub/support/lock'

module Travis
  module Hub
    module Services
      class UpdateJob
        include Helpers::Locking
        extend Instrumentation

        EVENTS = [:receive, :start, :finish, :cancel, :restart]

        attr_reader :event, :data

        def initialize(params)
          @event = params[:event].try(:to_sym)
          @data  = params[:data].symbolize_keys
        end

        def run
          validate
          process
          notify
        end
        instrument :run

        private

          def process
            exclusive "hub:update_job:#{build_id}" do
              update_job
            end
          end

          def notify
            Workers.new.cancel(job) if job.canceled? && event != :restart
          end

          def update_job
            job.send(:"#{event}!", data)
          end

          def job
            @job ||= Job.find(data[:id])
          end

          def build_id
            @build_id ||= Job.find(data[:id]).source_id
          end

          def validate
            EVENTS.include?(event) || unknown_event
          end

          def unknown_event
            fail ArgumentError, "Unknown event: #{event.inspect}, data: #{data}"
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
