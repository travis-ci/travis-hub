require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/addons/model/broadcast'

module Travis
  module Addons
    module Handlers
      class Insights < Base
        include Handlers::Task

        EVENTS = /(build|job):.*/

        def handle?
          !!ENV['INSIGHTS_ENABLED']
        end

        def handle
          Travis::Sidekiq.insights(event, payload)
        end

        private

          def payload
            {
              type: object.class.name,
              id: object.id,
              owner_type: object.owner_type,
              owner_id: object.owner_id,
              repository_id: object.repository_id,
              created_at: object.created_at,
              started_at: object.started_at,
              finished_at: object.finished_at,
              state: object.state
            }
          end

          class EventHandler < Addons::Instrument
            def notify_completed
              publish
            end
          end
          EventHandler.attach_to(self)
      end
    end
  end
end

