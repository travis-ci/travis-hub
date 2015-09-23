require 'metriks'
require 'travis/support/instrumentation'
require 'travis/hub/helper/locking'
require 'travis/hub/model/job'
require 'travis/hub/service/notify_workers'

module Travis
  module Hub
    module Service
      class UpdateJob
        include Helper::Locking
        extend Instrumentation

        EVENTS = [:receive, :start, :finish, :cancel, :restart]

        attr_reader :event, :data

        def initialize(params)
          @event = params[:event].try(:to_sym)
          @data  = params[:data].symbolize_keys
        end

        def run
          validate
          update_job
          notify
        end
        instrument :run

        private

          def update_job
            exclusive "hub:update_job:#{build_id}" do
              job.send(:"#{event}!", data)
            end
          end

          def notify
            NotifyWorkers.new.cancel(job) if event == :cancel
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
