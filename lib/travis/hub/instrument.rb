module Travis
  class Hub
    class Instrument
      module Handler
        class Request < Travis::Notification::Instrument
          def handle_received
            url = target.data['repository']['url'] rescue '?'
            publish(
              :msg => %(#{target.class.name}#handle received for type=#{target.type} repository="#{url}"),
              :data => target.data,
              :type => target.type
            )
          end

          def handle_completed
            url = target.data['repository']['url'] rescue '?'
            publish(
              :msg => %(#{target.class.name}#handle completed for type=#{target.type} repository="#{url}" in #{duration} seconds),
              :data => target.data,
              :type => target.type
            )
          end

          def authenticate_received
            publish(
              :login => target.credentials['login'],
              :msg => %(#{target.class.name}#authenticate received for #{target.credentials['login']})
            )
          end

          def authenticate_completed
            user = { :id => result.id, :login => result.login } if result
            result_message = result ? 'succeeded' : 'failed'
            publish(
              :user => user, :msg => %(#{target.class.name}#authenticate #{result_message} for #{result.login})
            )
          end
        end

        class Sync < Travis::Notification::Instrument
          def handle_received
            publish(
              :msg => %(#{target.class.name}#handle received for user_id="#{target.user_id}"),
              :user_id => target.user_id
            )
          end

          def handle_completed
            publish(
              :result => !!result,
              :msg => %(#{target.class.name}#handle completed for user_id="#{target.user_id}" in #{duration} seconds),
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
