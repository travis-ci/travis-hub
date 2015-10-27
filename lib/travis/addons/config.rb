require 'travis/secure_config'
require 'travis/addons/config/notify'
require 'travis/addons/helpers/hash'

module Travis
  module Addons
    class Config
      include Helpers::Hash

      attr_reader :payload, :build, :secure_key, :config

      def initialize(payload, secure_key = nil)
        @payload = payload
        @build = payload[:build]
        @config = deep_symbolize_keys(build.fetch(:config, {}))
        @secure_key = secure_key
      end

      def enabled?(key)
        return false unless notifications.respond_to?(:has_key?)
        return !!notifications[key] if notifications.has_key?(key) # TODO this seems inconsistent. what if email: { disabled: true }
        [:disabled, :disable].each { |key| return !notifications[key] if notifications.has_key?(key) } # TODO deprecate disabled and disable
        true
      end

      def send_on?(type, event)
        Notify.new(build, notifications).on?(type, event)
      end

      def values(type, key)
        config = notifications[type] rescue {}
        value  = config.is_a?(Hash) ? config[key] : config
        value.is_a?(Array) || value.is_a?(String) ? normalize_array(value) : value
      end

      def notifications
        @notifications ||= Travis::SecureConfig.decrypt(config.fetch(:notifications, {}) || {}, secure_key)
      end

      private

        def normalize_array(values)
          values = Array(values).compact
          values = values.map { |value| value.split(',') if value.is_a?(String) }
          values.compact.flatten.map(&:strip).reject(&:blank?)
        end

        def blank?(object)
          object.is_a?(NilClass) ? true : object.empty?
        end
    end
  end
end
