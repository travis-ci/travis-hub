require 'travis/instrumentation'
require 'travis/hub/helper/context'
require 'travis/hub/helper/locking'
require 'travis/hub/model/job'
require 'travis/hub/service/notify_workers'
require 'travis/hub/helper/limit'

module Travis
  module Hub
    module Service
      class UpdateJob < Struct.new(:event, :data)
        include Helper::Context, Helper::Locking, Helper::Limit
        extend Instrumentation

        EVENTS = [:receive, :start, :finish, :cancel, :restart]

        MSGS = {
          skipped: 'Skipped event job:%s for <Job id=%s> trying to update state from %s to %s data=%s',
          limited: 'Restarts limited: %s',
          support: 'Please try restarting this job later or contact support@travis-ci.com.'
        }

        def run
          exclusive do
            validate
            update_job
            notify
          end
        end
        instrument :run

        def job
          @job ||= Job.find(data[:id])
        rescue => e
          raise e
        end

        private

          def update_job
            return error_job if restarts.limited?
            skipped unless job.reload.send(:"#{event}!", attrs)
          end

          def error_job
            job.reload.finish!(state: :errored)
            job.add_log  MSGS[:limited] % MSGS[:support]
            logger.error MSGS[:limited] % restarts.to_s
          end

          def attrs
            data.reject { |key, _| key == :id }
          end

          def notify
            NotifyWorkers.new(context).cancel(job) if event == :cancel
          end

          def validate
            EVENTS.include?(event) || unknown_event
          end

          def exclusive(&block)
            super("hub:build-#{job.source_id}", &block)
          end

          def unknown_event
            fail ArgumentError, "Unknown event: #{event.inspect}, data: #{data}"
          end

          def skipped
            warn :skipped, event, job.id, job.state, data[:state], data
          end

          def restarts
            @restarts ||= Limit.new(redis, :restarts, job.id, config.limit.restarts)
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
