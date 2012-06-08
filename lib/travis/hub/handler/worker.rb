module Travis
  class Hub
    class Handler
      # Handles worker status events which are sent by the worker heartbeat.
      class Worker < Handler
        def handle
          reports = payload.is_a?(Hash) ? [payload] : payload
          reports.each { |report| handle_report(report) }
        end
        instrument :handle
        new_relic :handle

        protected

          def handle_report(report)
            if worker = worker_by(report.name, report.host)
              worker.ping(report)
            else
              ::Worker.create!(report.merge(:last_seen_at => Time.now.utc).to_hash)
            end
          end

          def worker_by(name, host)
            workers[[host, name].join(':')].try(:first)
          end

          def workers
            @workers ||= ::Worker.all.group_by(&:full_name)
          end
      end
    end
  end
end
