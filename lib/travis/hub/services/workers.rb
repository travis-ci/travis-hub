require 'travis/support/amqp'

module Travis
  module Hub
    module Services
      class Workers
        def cancel(job)
          publisher.publish(type: 'cancel_job', job_id: job.id, source: 'update_job_service')
        end

        private

          def publisher
            Amqp::FanoutPublisher.new('worker.commands')
          end
      end
    end
  end
end
