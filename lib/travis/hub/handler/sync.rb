require 'metriks'

module Travis
  class Hub
    class Handler
      class Sync < Handler
        #
        # Handles request messages which are created by the listener
        # when a github event comes in.
        def handle
          info "[handler/sync] type=#{type} user_id=#{user_id}"
          ::User.find(user_id).sync
        end
        instrument :handle, :scope => :type
        new_relic :handle

        private

          def type
            payload['type']
          end

          def user_id
            payload['user_id']
          end
      end
    end
  end
end
