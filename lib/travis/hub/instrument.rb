module Travis
  class Hub
    class Instrument
      module Handler
        class Request < Travis::Notification::Instrument
          def handle_completed
            url = target.data['repository']['url'] rescue '?'
            publish(
              :msg => %(#{target.class.name}#handle for type=#{target.type} repository="#{url}"),
              :data => target.data,
              :type => target.type
            )
          end

          def authenticate_completed
            user = { :id => result.id, :login => result.login } if result
            publish(
              :user => user, :msg => %(#{target.class.name}#authenticate #{result ? 'success' : 'failed'})
            )
          end
        end

        class Sync < Travis::Notification::Instrument
          def handle_completed
            publish(
              :result => !!result,
              :msg => %(#{target.class.name}#handle for user_id="#{target.user_id}"),
              :user_id => target.user_id
            )
          end
        end

        class Job < Travis::Notification::Instrument
          def update_completed
            publish(
              :msg => %(#{target.class.name}#update for #<Job id="#{target.payload['id']}">),
              :event => target.event,
              :payload => target.payload
            )
          end

          def log_completed
            # publish(
            #   :msg => %(#{target.class.name}#log for #<Job id="#{target.payload['id']}">),
            #   :event => target.event,
            #   :payload => target.payload
            # )
          end
        end
      end
    end
  end
end
