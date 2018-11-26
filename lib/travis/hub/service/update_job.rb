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
            with_state_update_count_check do
              update_job
              notify
            end
          end
        end
        instrument :run

        def job
          @job ||= Job.find(data[:id])
        rescue => e
          raise e
        end

        private

          def with_state_update_count_check
            unless data[:meta] && data[:meta]['uuid'] && data[:meta]['uuid'] != '' && data[:meta]['state_update_count']
              yield
              return
            end

            enabled = Rollout.matches?(:state_update_count, {
              uid:   job.repository.id,
              owner: job.repository.owner.login,
              repo:  job.repository.slug,
              redis: context.redis
            })
            unless enabled
              yield
              return
            end

            # uuid is unique to the worker job run
            uuid = data[:meta]['uuid']
            state_update_count = data[:meta]['state_update_count']
            key = "hub:state_update_count:#{job.id}:#{uuid}"

            # if the last event we received from this job run had a higher
            # state_update_count, discard the event to prevent out-of-order
            # processing.
            #
            # this prevents a scenario where we first process "job finished"
            # followed by "job started", leaving the job in a "started" state,
            # when the worker actually finished the job.
            stored_count = context.redis.get(key)
            if stored_count && stored_count.to_i > state_update_count
              context.logger.warn "stored state_update_count for key was higher than event key=#{key} stored=#{stored_count} event=#{state_update_count}"
              return
            end

            # set the new state_update_count ahead of time to mitigate racey
            # execution.
            context.redis.setex(key, 3600, state_update_count)

            yield
          end

          def store_instance_id
            return unless data[:meta] && data[:meta]['instance_id'] && data[:meta]['instance_id'] != '{unidentified}'

            instance_id = data[:meta]['instance_id']
            key = "hub:instance_id_job:#{instance_id}"
            ttl = 60*60*24*3 # 3 days
            context.redis.setex(key, ttl, job.id)
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
