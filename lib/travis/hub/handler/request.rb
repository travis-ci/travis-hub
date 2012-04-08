require 'multi_json'

module Travis
  class Hub
    class Handler
      class Request < Handler
        def handle
          if authenticated?
            debug "Creating Request with payload #{scm_payload.inspect}"
            ::Request.create_from(scm_payload, token)
          end
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
            MultiJson.decode(payload[:request])
          end
      end
    end
  end
end
