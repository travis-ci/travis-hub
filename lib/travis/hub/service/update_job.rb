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

        MSGS = {
          skipped: 'Skipped event job:%s for <Job id=%s> trying to update state from %s to %s data=%s',
        }

        attr_reader :event, :data, :job

        def initialize(params)
          @event = params[:event].try(:to_sym)
          @data  = normalize_data(params[:data])
          @job   = Job.find(data[:id])
        end

        def run
          exclusive do
            validate
            update_job
            notify
          end
        end
        instrument :run

        private

          def update_job
            warn :skipped unless job.reload.send(:"#{event}!", data)
          end

          def notify
            NotifyWorkers.new.cancel(job) if event == :cancel
          end

          def validate
            EVENTS.include?(event) || unknown_event
          end

          def normalize_data(data)
            data.delete(:state) if event == :restart
            data.symbolize_keys
          end

          def exclusive(&block)
            super("hub:build-#{job.source_id}", &block)
          end

          def unknown_event
            fail ArgumentError, "Unknown event: #{event.inspect}, data: #{data}"
          end

          def warn(msg)
            Hub.logger.warn MSGS[msg] % [event, job.id, job.state, data[:state], data]
          end

          class Instrument < Instrumentation::Instrument
            def run_received
              publish msg: "event: #{target.event} for repo=#{target.job.repository.slug} #{to_pairs(target.data)}"
            end

            def run_completed
              publish msg: "event: #{target.event} for repo=#{target.job.repository.slug} #{to_pairs(target.data)}"
            end
          end
          Instrument.attach_to(self)
        end
    end
  end
end
