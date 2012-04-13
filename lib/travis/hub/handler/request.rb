require 'metriks'

module Travis
  class Hub
    class Handler
      class Request < Handler
        def handle
          track_event
          if authenticated?
            track_event(:authenticated)
            debug "Creating Request with payload #{scm_payload.inspect}"
            ::Request.create_from(scm_payload, token)
            track_event(:created)
          end
        rescue StandardError => e
          track_event(:failed)
          raise
        end

        protected

          def authenticated?
            debug "Authenticating #{login} with token #{token}"
            return unless token = ::Token.find_by_token(token)
            token.user.login == login
          end

          def login
            payload[:credentials][:login]
          end

          def token
            payload[:credentials][:token]
          end

          def scm_payload
            payload[:request]
          end

          def track_event(name = nil)
            meter_name = 'travis.hub.build_requests.received'
            meter_name = "#{meter_name}.#{name.to_s}" if name
            Metriks.meter(meter_name).mark
          end
      end
    end
  end
end
