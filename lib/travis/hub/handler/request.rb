require 'metriks'

module Travis
  class Hub
    class Handler
      class Request < Handler
        # Handles request messages which are created by the listener
        # when a github event comes in.

        class ProcessingError < StandardError; end

        attr_reader :user

        def type
          payload['type']
        end

        def credentials
          payload['credentials']
        end

        def data
          @data ||= payload['payload'] ? MultiJson.decode(payload['payload']) : nil
        end

        def handle
          raise(ProcessingError, "the #{type} payload was empty and could not be processed") unless data
          receive if authenticated?
        end
        instrument :handle, :scope => :type
        new_relic :handle

        private

          def receive
            Travis.run_service(:receive_request, user, :event_type => type, :payload => data, :token => credentials['token'])
          end

          def requeue
            Travis.run_service(:requeue_request, user, :build_id => payload['build_id'], :token => credentials['token']) .run
          end

          # TODO move authentication to the service
          def authenticated?
            !!authenticate
          end

          def authenticate
            p credentials
            @user = User.authenticate_by(credentials)
          end
          instrument :authenticate, :scope => :type

          Travis::Hub::Instrument::Handler::Request.attach_to(self)
      end
    end
  end
end
