require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Intercom < Base
        include Handlers::Task

        EVENTS = /(build):(created|started|restarted)/

        def handle?
          owner_type.downcase == 'user'
        end

        def handle
          params = {
            event: :report_build,
            owner_id: owner_id,
            last_build_at: last_build_at
          }
          run_task(:intercom, params)
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish
          end
        end
        Instrument.attach_to(self)

        private

        def last_build_at
          DateTime.now
        end

        def owner
          object.owner || nil
        end

        def owner_id
          owner.id.to_s if owner
        end

        def owner_type
          owner ? owner.class.name : ''
        end

      end
    end
  end
end
