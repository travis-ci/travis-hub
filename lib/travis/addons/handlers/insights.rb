require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/addons/support/insights'
require 'travis/rollout'

module Travis
  module Addons
    module Handlers
      class Insights < Base
        include Handlers::Task

        EVENTS = /(build|job):(created|started|finished|canceled|errored|restarted)/

        def initialize(event, params = {})
          super
          @event = event.sub(/(canceled|errored)/, 'finished')
        end

        def handle?
          !!ENV['INSIGHTS_ENABLED']
        end

        def handle
          post? ? post : enqueue
        end

        private

          def post?
            Rollout.matches?(:insights_http, owner: owner_name)
          end

          def post
            insights.post(event: event, data: data)
          end

          def enqueue
            Travis::Sidekiq.insights(event, data)
          end

          def data
            {
              type: object.class.name,
              id: object.id,
              owner_type: object.owner_type,
              owner_id: object.owner_id,
              repository_id: object.repository_id,
              private: !!object.private?,
              state: state,
              created_at: object.restarted_at || object.created_at,
              started_at: object.started_at,
              finished_at: object.finished_at
            }
          end
          alias payload data

          def state
            case event
            when 'job:created' then :created
            when 'job:started' then :started
            else object.state
            end
          end

          def owner_name
            object.owner&.login
          end

          def insights
            Travis::Insights.new(Hub.context.config)
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

