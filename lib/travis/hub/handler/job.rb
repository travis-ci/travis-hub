module Travis
  class Hub
    class Handler
      # Handles updates from test jobs running on the worker, i.e. events
      # like job:test:started, job:test:log and job:test:finished
      class Job < Handler
        def handle
          case event
          when 'job:test:log'
            log
          else
            update
          end
        end

        protected

          def job
            @job ||= ::Job.find(payload['id'])
          end

          def update
            # TODO hot compat, remove after migration to result columns
            payload['result'] = payload.delete('status') if payload.key?('status')
            job.update_attributes(payload)
          end
          instrument :update
          new_relic :update

          def log
            # TODO hot compat, remove once workers publish to "reporting.jobs.logs" directly
            publisher = Travis::Amqp::Publisher.jobs('logs')
            publisher.publish(:data => payload, :uuid => Travis.uuid)
          end
          instrument :log
          new_relic :log

          Travis::Hub::Instrument::Handler::Job.attach_to(self)
      end
    end
  end
end
