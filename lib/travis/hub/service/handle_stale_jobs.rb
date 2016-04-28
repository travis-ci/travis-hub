require 'travis/instrumentation'
require 'travis/hub/helper/context'
require 'travis/hub/helper/locking'
require 'travis/hub/model/job'
require 'travis/hub/service/notify_workers'

module Travis
  module Hub
    module Service
      class HandleStaleJobs
        include Helper::Context, Helper::Locking
        extend Instrumentation

        STALE_STATES = %w(queued received started)
        OFFSET       = 6 * 3600
        MSGS         = {
          stale_job: 'A stale job with the id: %s and which was last updated: %s and had the state: %s was errored.'
        }

        def run
          stale_jobs.each { |job| error(job) }
        end

        private

          def stale_jobs
            Job.where('updated_at <= ?', Time.now - OFFSET).where(state: STALE_STATES)
          end

          def error(job)
            logger.info(MSGS[:stale_job] % [job.id, job.updated_at, job.state])
            job.finish!(state: :errored, finished_at: Time.now)
          end
      end
    end
  end
end



