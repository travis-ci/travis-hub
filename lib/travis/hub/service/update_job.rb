require 'travis/instrumentation'
require 'travis/hub/helper/context'
require 'travis/hub/helper/locking'
require 'travis/hub/model/job'
require 'travis/hub/service/error_job'
require 'travis/hub/service/notify_workers'
require 'travis/hub/service/notify_trace_processor'
require 'travis/hub/helper/limit'

module Travis
  module Hub
    module Service
      class UpdateJob < Struct.new(:event, :data)
        include Helper::Context, Helper::Locking
        extend Instrumentation

        EVENTS = [:receive, :reset, :start, :finish, :cancel, :restart]

        MSGS = {
          skipped: 'Skipped event job:%s for <Job id=%s> trying to update state from %s to %s data=%s',
        }

        def run
          exclusive do
            validate
            store_instance_id
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

          def store_instance_id
            if data[:meta] && data[:meta]['instance_id'] && data[:meta]['instance_id'] != 'unknown instance'
              instance_id = data[:meta]['instance_id']
              key = "hub:instance_id_job:#{instance_id}"
              ttl = 60*60*24*3 # 3 days
              context.redis.setex(key, ttl, job.id)
            end
          end

          def update_job
            return error_job if event == :reset && resets.limited? && !job.finished?

            if ENV['CANCELLATION_DISABLED'] == 'true' && (event == :cancel || recancel?)
              raise 'cancellation has been disabled'
            end

            return recancel if recancel?
            return skipped if skip_canceled?
            return skipped unless job.reload.send(:"#{event}!", attrs)
            resets.record if event == :reset
          end

          def error_job
            ErrorJob.new(context, id: job.id, reason: :resets_limited, resets: resets.to_s).run
          end

          def notify
            NotifyWorkers.new(context).cancel(job) if job.reload.state == :canceled
            NotifyTraceProcessor.new(context).notify(job, data) if event == :finish
          end

          def validate
            EVENTS.include?(event) || unknown_event
          end

          def skip_canceled?
            [:reset, :recieve, :start, :finish].include?(event) && job.canceled?
          end

          def recancel?
            [:receive, :start].include?(event) && (job.errored? || job.canceled?)
          end

          def recancel
            NotifyWorkers.new(context).cancel(job)
          end

          def skipped
            warn :skipped, event, job.id, job.state, data[:state], data
          end

          def resets
            @resets ||= Limit.new(redis, :resets, job.id, config.limit.resets)
          end

          def attrs
            data.reject { |key, _| key == :id || key == :meta }
          end

          def unknown_event
            fail ArgumentError, "Unknown event: #{event.inspect}, data: #{data}"
          end

          def exclusive(&block)
            super("hub:build-#{job.source_id}", config.lock, &block)
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
