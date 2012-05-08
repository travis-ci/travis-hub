require 'metriks'

module Travis
  class Hub
    class Handler
      class Request < Handler
        # Handles request messages which are created by the listener
        # when a github event comes in.
        def handle
          info "[handler/request] type=#{type} repository=#{request['repository']['html_url']}"
          track_event
          if authenticate
            track_event(:authenticated)
            create_request
          else
            warn "[handler/request] Could not authenticate #{login} with #{token} for payload #{payload.inspect}"
          end
        rescue StandardError => e
          track_event(:failed)
          raise
        end

        protected

          def authenticate
            debug "Authenticating #{login} with token #{token}"
            Thread.current[:current_user] = User.authenticate_by_token(login, token)
          end

          def create_request
            debug "Creating Request with payload #{request.inspect}"
            ::Request.create_from(type, request, token)
            track_event(:created)
          end

          def login
            payload[:credentials][:login]
          end

          def type
            payload[:type]
          end

          def token
            payload[:credentials][:token]
          end

          def request
            payload[:request]
          end

          def track_event(name = nil)
            meter_name = "travis.hub.build_requests.#{type}.received"
            meter_name = "#{meter_name}.#{name.to_s}" if name
            Metriks.meter(meter_name).mark
          end
      end
    end
  end
end
