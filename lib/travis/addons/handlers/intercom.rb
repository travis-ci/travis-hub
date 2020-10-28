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
            owner_id: owner.id,
            last_build_at: build.started_at
          }
          puts '============== intercom debug ================'
          puts params.inspect
          puts '============== intercom debug ================'
          run_task(:intercom, params)
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish
          end
        end
        Instrument.attach_to(self)

        private

        def build
          object.build || {}
        end

        def owner
          object.owner || {}
        end

        def owner_type
          owner.class.name || ''
        end

      end
    end
  end
end
