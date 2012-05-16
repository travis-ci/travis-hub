module Travis
  class Hub
    class Handler
      # Handles updates from test jobs running on the worker, i.e. events
      # like job:test:started, job:test:log and job:test:finished
      class Job < Handler
        include do
          def handle
            case event.to_sym
            when :'job:test:log'
              handle_log_update
            else
              handle_update
            end
          end

          protected

            def job
              @job ||= ::Job.find(payload[:id])
            end

            def handle_update
              # TODO hot compat, remove after migration to result columns
              payload[:result] = payload.delete(:status) if payload.key?(:status)
              job.update_attributes(payload.to_hash)
            end

            def handle_log_update
              ::Job::Test.append_log!(payload[:id], payload.log)
            end
        end
      end
    end
  end
end
