require 'metriks'

module Travis
  class Hub
    class Handler
      class Request < Handler
        # Handles request messages which are created by the listener
        # when a github event comes in.
        def handle
          info "[handler/request] type=#{type} repository=#{request["repository"]["html_url"]}"
          track_event
          if authenticated?
            track_event(:authenticated)
            debug "Creating Request with payload #{request.inspect}"
            ::Request.create_from(type, request, token)
            track_event(:created)
          else
            warn "[handler/request] Could not authenticate #{login} with #{token}"
          end
        rescue StandardError => e
          track_event(:failed)
          raise
        end

        protected

          def authenticated?
            debug "Authenticating #{login} with token #{token}"
            token = ::Token.find_by_token(self.token)
            token and token.user.login == login
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
