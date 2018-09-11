require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/addons/model/broadcast'

module Travis
  module Addons
    module Handlers
      class LogSearch < Base
        include Handlers::Task

        # alias log_search => logsearch
        register('logsearch', self)

        EVENTS = 'job:finished'

        def handle?
          ENV['LOGSEARCH_ENABLED'] == 'true'
        end

        def handle
          Travis::Sidekiq.logsearch(object.id)
        end

        private

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
