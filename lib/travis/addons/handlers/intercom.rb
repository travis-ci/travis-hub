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
          run_task(:intercom, payload)
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish
          end
        end
        Instrument.attach_to(self)

        private

        def owner_type
          owner = object.owner || {}
          owner.class.name || ''
        end

      end
    end
  end
end
