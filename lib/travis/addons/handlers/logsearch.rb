require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/addons/model/broadcast'
require 'travis/rollout'

module Travis
  module Addons
    module Handlers
      class LogSearch < Base
        include Handlers::Task

        # alias logsearch => log_search
        Event::Handler.register('logsearch', self)

        EVENTS = 'job:finished'

        def handle?
          return false unless ENV['LOGSEARCH_ENABLED'] == 'true'

          # random uid to sample randomly (not tied to user)
          Rollout.matches?(:logsearch, {
            uid:   SecureRandom.hex,
            owner: object.repository.owner.login,
            repo:  object.repository.slug,
            redis: Travis::Hub.context.redis
          })
        end

        def handle
          Travis::Sidekiq.logsearch(object.id)
        end

        private

          def payload
            object.id
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
