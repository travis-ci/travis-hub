require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Intercom < Base
        include Handlers::Task

        EVENTS = 'build:created'

        def handle?
          puts "Intercom debugging: handle?"
          puts owner_type
          puts "------------------"
          owner_type.downcase == 'user' # currently Intercom makes sense only for users, not for orgs
        end

        def handle
          run_task(:intercom, payload)
        end

        private

        def owner_type
          owner = object.owner || {}
          owner.class.name || ''
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish
          end
        end
        Instrument.attach_to(self)

      end
    end
  end
end
