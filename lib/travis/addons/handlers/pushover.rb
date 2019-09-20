require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Pushover < Base
        include Handlers::Task

        EVENTS = 'build:finished'

        def handle?
          !pull_request? && config.values(:pushover, :users).any?(&:present?) && config.notifications.any? { |cfg| cfg[:pushover] && cfg[:pushover][:api_key].present? } && config.send_on?(:pushover, action)
        end

        def handle
          config.notifications.each do |cfg|
            run_task(:pushover, payload, users: users(cfg), api_key: api_key(cfg))
          end
        end

        def users(cfg)
          config = cfg[:pushover] rescue {}
          value  = config.is_a?(Hash) ? config[:users] : config
          value.is_a?(Array) || value.is_a?(String) ? normalize_array(value) : value
        end

        def api_key(cfg)
          decrypted = Travis::SecureConfig.decrypt(cfg, secure_key)
          if decrypted.is_a? Hash
            notifications = [decrypted]
          else
            notifications = Array(decrypted)
          end
          decrypted[:pushover][:api_key]
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish(users: handler.users, api_key: handler.api_key)
          end
        end
        Instrument.attach_to(self)

        private
        def normalize_array(values)
          values = Array(values).compact
          values = values.map { |value| value.split(',') if value.is_a?(String) }
          values.compact.flatten.map(&:strip).reject(&:blank?)
        end
      end
    end
  end
end
