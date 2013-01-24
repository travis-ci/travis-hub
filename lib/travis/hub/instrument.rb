module Travis
  class Hub
    class Instrument
      module Handler
        class Job < Travis::Notification::Instrument
          def update_completed
            publish(
              :msg => %(for #<Job id="#{target.payload['id']}">),
              :event => target.event,
              :payload => target.payload
            )
          end

          def log_completed
            # publish(
            #   :msg => %(for #<Job id="#{target.payload['id']}">),
            #   :event => target.event,
            #   :payload => target.payload
            # )
          end
        end
      end
    end
  end
end
