module Travis
  class Hub
    class Handler
      class Worker < Handler
        def handle
          case event.to_sym
          when :'worker:status'
            payload.each do |report|
              if worker = worker_by(report.name, report.host)
                worker.ping!
                worker.set_state(report.state) if report.state?
              else
                ::Worker.create!(:name => report.name, :host => report.host, :last_seen_at => Time.now.utc, :state => report.state)
              end
            end
          end
        end

        protected

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
