require 'metriks'

module Travis
  class Hub
    class Handler
      class Sync < Handler
        #
        # Handles request messages which are created by the listener
        # when a github event comes in.
        def handle
          Travis.run_service(:sync_user, id: user_id)
        end
        instrument :handle
        new_relic  :handle

        def user_id
          payload['user_id']
        end

        Travis::Hub::Instrument::Handler::Sync.attach_to(self)
      end
    end
  end
end
