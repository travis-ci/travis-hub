require 'travis/amqp'

module Travis
  module Hub
    module Service
      class NotifyWorkers < Struct.new(:context)
        def cancel(job)
          publisher.publish(type: 'cancel_job', job_id: job.id, source: 'hub')
        end

        private

          def publisher
            # TODO use context.amqp
            Travis::Amqp::FanoutPublisher.new('worker.commands')
          end
      end
    end
  end
end
