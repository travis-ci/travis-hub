require 'travis/secure_config'
require 'travis/addons/config/notify'
require 'travis/addons/helpers/hash'

module Travis
  module Addons
    class Config
      include Helpers::Hash

      attr_reader :build, :config

      def initialize(build, config)
        @build = build
        @config = config.is_a?(Hash) ? deep_symbolize_keys(config) : config
      end

      def [](key)
        config[key] if config.is_a?(Hash)
      end

      def key?(key)
        config.key?(key) if config.is_a?(Hash)
      end

      def enabled?
        return false unless config
        return true unless config.respond_to?(:key?)
        return false if config.key?(:enabled) && !config[:enabled]
        [:disabled, :disable].each { |key| return !config[key] if config.key?(key) } # TODO deprecate disabled and disable
        true
      end

      def send_on?(type, event)
        Notify.new(build, config.is_a?(Hash) ? config : {}).on?(type, event)
      end

      def values(key)
        value = config
        value = value.is_a?(Hash) ? value[key] : value
        value.is_a?(Array) || value.is_a?(String) ? normalize_strings(value) : value
      end

      private

        def normalize_strings(values)
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
