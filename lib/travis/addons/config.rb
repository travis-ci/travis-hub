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
        notifications.any? do |notifier|
          if !notifier.respond_to?(:has_key?)
            false
          elsif notifier.has_key?(key)
            !!notifier[key]
          elsif notifier.has_key?(:disabled)
            !notifier[:disabled]
          elsif notifier.has_key?(:disable)
            !notifier[:disable]
          else
            true
          end
        end
      end

      def send_on?(type, event)
        notifications.any? do |notifier|
          Notify.new(build, notifier).on?(type, event)
        end
      end

      def values(type, key)
        notifications.map do |notifier|
          config = notifier[type] rescue {}
          value  = config.is_a?(Hash) ? config[key] : config
          value.is_a?(Array) || value.is_a?(String) ? normalize_array(value) : value
        end
      end

      def notifications
        return @notifications if @notifications
        decrypted = Travis::SecureConfig.decrypt(config.fetch(:notifications, {}) || {}, secure_key)
        if decrypted.is_a? Hash
          @notifications = [decrypted]
        else
          @notifications = Array(decrypted)
        end
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
