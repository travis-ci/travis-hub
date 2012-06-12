module Travis
  class Hub
    class Handler
      # Handles updates from test jobs running on the worker, i.e. events
      # like job:test:started, job:test:log and job:test:finished
      class Job < Handler
        def handle
          case event.to_sym
          when :'job:test:log'
            log
          else
            update
          end
        end

        protected

          def job
            @job ||= ::Job.find(payload[:id])
          end

          def update
            # TODO hot compat, remove after migration to result columns
            payload[:result] = payload.delete(:status) if payload.key?(:status)
            job.update_attributes(payload.to_hash)
          end
          instrument :update
          new_relic :update

          def log
            ::Job::Test.append_log!(payload[:id], payload.log)
          end
          instrument :log
          new_relic :log

          Travis::Hub::Instrument::Handler::Job.attach_to(self)
      end
    end
  end
end
