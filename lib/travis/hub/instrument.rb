module Travis
  class Hub
    module Instrument
      module Handler
        class Request < Travis::Notification::Instrument
          def handle
            publish(
              :msg => %(#{target.class.name}#handle for type=#{target.type} repository="#{target.github_payload[:repository][:url]}">),
              :payload => target.github_payload,
              :type => target.type
            )
          end

          def authenticate
            publish(
              :msg => %(#{target.class.name}#authenticate #{result ? 'success' : 'failed'}),
            )
          end
        end

        class Job < Travis::Notification::Instrument
          def update
            publish(
              :msg => %(#{target.class.name}#update for #<Job id="#{target.payload[:id]}">),
              :event => target.event,
              :payload => target.payload
            )
          end

          def log
            publish(
              :msg => %(#{target.class.name}#log for #<Job id="#{target.payload[:id]}">),
              :event => target.event,
              :payload => target.payload
            )
          end
        end
      end
    end
  end
end
