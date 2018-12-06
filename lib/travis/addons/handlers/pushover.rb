require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Pushover < Base
        include Handlers::Task

        EVENTS = 'build:finished'

        def handle?
          !pull_request? && users.present? && api_key.present? && config.send_on?(:pushover, action) && !silent?
        end

        def handle
          run_task(:pushover, payload, users: users, api_key: api_key)
        end

        def users
          @users ||= config.values(:pushover, :users)
        end

        def api_key
          @api_key ||= config.notifications[:pushover][:api_key]
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish(users: handler.users, api_key: handler.api_key)
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end
