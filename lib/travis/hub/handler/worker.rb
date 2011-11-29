module Travis
  class Hub
    class Handler
      class Worker < Handler
        def initialize(event, payload)
          @event = event
          @payload = Hashr.new(payload)
        end

        def handle
          case event.to_sym
          when :'worker:status'
            payload.each do |name, report|
              if worker = worker_by(name, report.host)
                worker.ping!
                worker.set_state(payload.state) if payload.state?
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
