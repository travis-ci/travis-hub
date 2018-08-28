require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/addons/model/broadcast'

module Travis
  module Addons
    module Handlers
      class Insights < Base
        include Handlers::Task

        EVENTS = /(job):(created|started|finished|canceled|errored)/

        def handle?
          !!ENV['INSIGHTS_ENABLED']
        end

        def handle
          Travis::Sidekiq.insights(event, payload)
        end

        def event
          super.sub(/(canceled|errored)/, 'finished')
        end

        private

          def payload
            {
              type: object.class.name,
              id: object.id,
              owner_type: object.owner_type,
              owner_id: object.owner_id,
              repository_id: object.repository_id,
              state: object.state,
              created_at: object.created_at,
              started_at: object.started_at,
              finished_at: object.finished_at
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

