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
          skipped: 'Skipped event job:%s for <Job id=%s> trying to update state from %s to %s',
        }

        attr_reader :event, :data

        def initialize(params)
          @event = params[:event].try(:to_sym)
          @data  = params[:data].symbolize_keys
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
            log :skipped unless job.send(:"#{event}!", data)
          end

          def notify
            NotifyWorkers.new.cancel(job) if event == :cancel
          end

          def job
            @job ||= Job.find(data[:id])
          end

          def build_id
            @build_id ||= Job.where(id: data[:id]).select(:source_id).pluck(:source_id).first
          end

          def validate
            EVENTS.include?(event) || unknown_event
          end

          def exclusive(&block)
            super("hub:build-#{build_id}", &block)
          end

          def unknown_event
            fail ArgumentError, "Unknown event: #{event.inspect}, data: #{data}"
          end

          def log(msg)
            Hub.logger.info MSGS[msg] % [event, job.id, job.state, data[:state]]
          end

          class Instrument < Instrumentation::Instrument
            def run_received
              publish msg: "event: #{target.event} for <Job id=#{target.data[:id]}> #{to_pairs(target.data)}"
            end

            def run_completed
              publish msg: "event: #{target.event} for <Job id=#{target.data[:id]}> #{to_pairs(target.data)}"
            end
          end
          Instrument.attach_to(self)
        end
    end
  end
end
