require 'metriks'

module Travis
  class Hub
    class Handler
      class Request < Handler
        # Handles request messages which are created by the listener
        # when a github event comes in.
        def type
          payload['type']
        end

        def credentials
          payload['credentials']
        end

        def data
          @data ||= MultiJson.decode(payload['payload'])
        end

        def handle
          ::Request.receive(type, data, credentials['token']) if authenticated?
        end
        instrument :handle, :scope => :type
        new_relic :handle

        private

          def authenticated?
            !!authenticate
          end

          def authenticate
            User.authenticate_by(credentials)
          end
          instrument :authenticate, :scope => :type

          Travis::Hub::Instrument::Handler::Request.attach_to(self)
      end
    end
  end
end
