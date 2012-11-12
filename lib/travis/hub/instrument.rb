module Travis
  class Hub
    class Instrument
      module Handler
        class Request < Travis::Notification::Instrument
          def handle_received
            url = target.data['repository']['url'] rescue '?'
            publish(
              :msg => %(for type=#{target.type} repository="#{url}"),
              :data => target.data,
              :type => target.type
            )
          end

          def handle_completed
            url = target.data['repository']['url'] rescue '?'
            publish(
              :msg => %(for type=#{target.type} repository="#{url}"),
              :data => target.data,
              :type => target.type
            )
          end

          def authenticate_received
            publish(
              :msg => %(for #{target.credentials['login']}),
              :login => target.credentials['login']
            )
          end

          def authenticate_completed
            user = { :id => result.id, :login => result.login } if result
            result_message = result ? 'succeeded' : 'failed'
            publish(
              :msg => %(#{result_message} for #{target.credentials['login']}),
              :user => user
            )
          end
        end

        class Sync < Travis::Notification::Instrument
          def handle_received
            publish(
              :msg => %(for user_id="#{target.user_id}"),
              :user_id => target.user_id
            )
          end

          def handle_completed
            publish(
              :result => !!result,
              :msg => %(for user_id="#{target.user_id}"),
              :user_id => target.user_id
            )
          end
        end

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
