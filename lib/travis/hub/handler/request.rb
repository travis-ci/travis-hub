require 'metriks'

module Travis
  class Hub
    class Handler
      class Request < Handler
        # Handles request messages which are created by the listener
        # when a github event comes in.
        def handle
          info "[handler/request] type=#{type} repository=#{github_payload}"
          if authenticate
            create
          else
            warn "[handler/request] Could not authenticate #{login} with #{token} for payload #{payload.inspect}"
          end
        end
        instrument :handle, :scope => :type
        new_relic :handle

        private

          def authenticate
            debug "Authenticating #{login} with token #{token}"
            Thread.current[:current_user] = User.authenticate_by_token(login, token)
          end
          instrument :authenticate, :scope => :type

          def create
            debug "Creating Request with payload #{payload.inspect}"
            ::Request.create_from(type, github_payload, token)
          end
          instrument :create, :scope => :type

          def login
            payload[:credentials][:login]
          end

          def type
            payload[:type]
          end

          def token
            payload[:credentials][:token]
          end

          def github_payload
            payload[:request] || payload[:payload] # TODO hot compat. remove :request once listener pushes :payload
          end
      end
    end
  end
end
