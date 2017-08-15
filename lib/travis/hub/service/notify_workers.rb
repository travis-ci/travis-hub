require 'travis/hub/support/job_board'

module Travis
  module Hub
    module Service
      class NotifyWorkers < Struct.new(:context)
        include Helper::Context

        MSGS = {
          cancel: 'Broadcasting cancelation message for <Job id=%s state=%s>',
        }

        def cancel(job)
          info :cancel, job.id, job.state
          cancel_via_job_board(job)
          cancel_via_amqp(job)
        end

        private

          def cancel_via_job_board(job)
            job_board.cancel(job.id)
          end

          def cancel_via_amqp(job)
            context.amqp.fanout(
              'worker.commands',
              type: 'cancel_job', job_id: job.id, source: 'hub'
            )
          end

          def job_board
            @job_board ||= Travis::Hub::Support::JobBoard.new(
              context.config.job_board.to_h
            )
          end
      end
    end
  end
end
