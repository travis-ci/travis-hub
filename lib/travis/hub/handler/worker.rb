module Travis
  class Hub
    class Handler
      # Handles worker status events which are sent by the worker heartbeat.
      class Worker < Handler
        def handle
          # TODO hot compat, remove the next line once all workers send the new payload
          reports = payload.is_a?(Hash) ? payload['workers'] || payload : payload
          # reports = payload['workers']
          reports = [reports] if reports.is_a?(Hash)
          reports.each { |report| handle_report(report) }
        end
        instrument :handle
        new_relic :handle

        protected

          def handle_report(report)
            worker = worker_by(report['name'], report['host'])
            worker ||= ::Worker.create!(report)
            worker.ping(report)
          end

          def worker_by(name, host)
            workers[[host, name].join(':')]
          end

          def workers
            @workers ||= ::Worker.all.inject({}) do |workers, worker|
              workers[worker.full_name] = worker
            end
          end
      end
    end
  end
end
