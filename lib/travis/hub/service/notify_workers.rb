require 'travis/support/amqp'

module Travis
  module Hub
    module Service
      class NotifyWorkers
        def cancel(job)
          publisher.publish(type: 'cancel_job', job_id: job.id, source: 'hub')
        end

        private

          def publisher
            Amqp::FanoutPublisher.new('worker.commands')
          end
      end
    end
  end
end
