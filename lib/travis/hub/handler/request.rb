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
            Travis::Services.run(:requests, :receive, user, :event_type => type, :payload => data, :token => credentials['token'])
          end

          # def requeue
          #   Services::Requests::Requeue.new(user, :build_id => payload['build_id'], :token => credentials['token']) .run
          # end

          def authenticated?
            !!authenticate
          end

          def authenticate
            @user = User.authenticate_by(credentials)
          end
          instrument :authenticate, :scope => :type

          Travis::Hub::Instrument::Handler::Request.attach_to(self)
      end
    end
  end
end
