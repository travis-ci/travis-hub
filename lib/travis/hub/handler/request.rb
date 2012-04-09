require 'metriks'

module Travis
  class Hub
    class Handler
      class Request < Handler
        def handle
          increment_counter
          if authenticated?
            increment_counter(:authenticated)
            debug "Creating Request with payload #{scm_payload.inspect}"
            ::Request.create_from(scm_payload, token)
            increment_counter(:created)
          end
        rescue StandardError => e
          increment_counter(:failed)
          raise
        end

        protected

          def authenticated?
            debug "Authenticating #{login} with token #{token}"
            ::Token.find_by_token(token).user.login == login
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

          def increment_counter(name = nil)
            meter_name = 'travis.hub.build_requests.received'
            meter_name = "#{meter_name}.#{name.to_s}" if name
            Metriks.meter(meter_name).mark
          end
      end
    end
  end
end
