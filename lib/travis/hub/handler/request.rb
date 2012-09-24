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
          # TODO hot compat. remove :request once listener pushes :payload
          # TODO why do we get empty requests (without 'request' or 'payload' being set)?
          @data ||= MultiJson.decode(payload['request'] || payload['payload'] || '{}')
        end

        def handle
          ::Request.receive(type, data, credentials['token']) if authenticate && !data.empty?
        end
        instrument :handle, :scope => :type
        new_relic :handle

        private

          def authenticate
            Thread.current[:current_user] = User.authenticate_by(credentials)
          end
          instrument :authenticate, :scope => :type

          Travis::Hub::Instrument::Handler::Request.attach_to(self)
      end
    end
  end
end
