module Travis
  module Hub
    module Service
      class NotifyWorkers < Struct.new(:context)
        def cancel(job)
          context.amqp.fanout('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
        end
      end
    end
  end
end
