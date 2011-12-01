module Travis
  class Hub
    class Handler
      class Worker < Handler
        def handle
          case event.to_sym
          when :'worker:status'
            (payload.is_a?(Hash) ? [payload] : payload).each { |report| handle_report(report) }
          end
        end

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
