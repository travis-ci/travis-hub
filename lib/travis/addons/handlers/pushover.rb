require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Pushover < Notifiers
        EVENTS = 'build:finished'
        KEY = :pushover

        class Notifier < Notifier
          def handle?
            !pull_request? && users.present? && api_key.present? && config.send_on?(:pushover, action)
          end

          def handle
            run_task(:pushover, payload, users: users, api_key: api_key, template: template)
          end

          def users
            @users ||= config.values(:users)
          end

          def api_key
            @api_key ||= config[:api_key]
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
end
