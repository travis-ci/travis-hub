require 'travis/hub/support/job_board'

module Travis
  module Hub
    module Service
      class NotifyWorkers < Struct.new(:context)
        include Helper::Context

        MSGS = {
          amqp_cancel: 'Broadcasting cancelation message for <Job id=%s state=%s>',
          job_board_cancel: 'Canceling via Job Board delete for <Job id=%s state=%s>'
        }

        def cancel(job)
          cancel_via_job_board(job)
          cancel_via_amqp(job)
        end

        private

          def cancel_via_job_board(job)
            return if context.config.job_board.url.to_s =~ /not:set/

            info :job_board_cancel, job.id, job.state
            job_board.cancel(job.id)
          end

          def cancel_via_amqp(job)
            info :amqp_cancel, job.id, job.state
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
