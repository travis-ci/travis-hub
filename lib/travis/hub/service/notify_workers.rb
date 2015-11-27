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
            Travis::Amqp::FanoutPublisher.new('worker.commands')
          end
      end
    end
  end
end
