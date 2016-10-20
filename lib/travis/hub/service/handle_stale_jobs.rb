require 'travis/instrumentation'
require 'travis/hub/helper/context'
require 'travis/hub/helper/locking'
require 'travis/hub/model/job'

module Travis
  module Hub
    module Service
      class HandleStaleJobs
        include Helper::Context, Helper::Locking
        extend Instrumentation

        STALE_STATES = %w(queued received started)
        OFFSET       = 6 * 3600
        MSGS         = {
          run_stale_job: 'Cleanup stale job started.',
          stale_job: 'Erroring stale job: id=%s state=%s updated_at=%s.'
        }

        def run
          logger.info(MSGS[:run_stale_job])
          stale_jobs.each { |job| error(job) }
        end

        private

          def stale_jobs
            Job.where('updated_at <= ?', Time.now - OFFSET).where(state: STALE_STATES)
          end

          def error(job)
            logger.info(MSGS[:stale_job] % [job.id, job.state, job.updated_at])
            job.finish!(state: :errored, finished_at: Time.now)
          end
      end
    end
  end
end
