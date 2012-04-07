require 'multi_json'

module Travis
  class Hub
    class Handler
      class Request < Handler
        def handle
          if authenticated?
            Request.create_from(scm_payload, token)
          end
        end

        protected

          def authenticated?
            Token.find_by_token(token).user.login == login
          end

          def login
            payload[:credentials][:login]
          end

          def token
            payload[:credentials][:token]
          end

          def scm_payload
            MultiJson.decode(payload[:credentials][:request])
          end
      end
    end
  end
end
