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
          context.amqp.fanout('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
          context.job_board.remove(job.id)
        end
      end
    end
  end
end
