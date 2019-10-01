require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/array/wrap'
require 'travis/secure_config'

module Travis
  class SecureConfig
    class Obfuscate < Struct.new(:config, :key)
      ENV_VAR_PATTERN = /(?<=\=)(?:(?<q>['"]).*?[^\\]\k<q>|(.*?)(?= \w+=|$))/

      def run
        config = self.config.except(:source_key)
        config[:env] = obfuscate(config[:env]) if config[:env]
        config[:global_env] = obfuscate(config[:global_env]) if config[:global_env]
        config
      end

      private

        def obfuscate(env)
          Array.wrap(env).map do |value|
            obfuscate_values(value).join(' ')
          end
        end

        def obfuscate_values(values)
          Array.wrap(values).compact.map do |value|
            value = obfuscate_value(value)
            value = value.map { |key, value| [key, value].join('=') } if value.is_a?(Hash)
            value
          end
        end

        def obfuscate_value(value)
          secure.decrypt(value) do |decrypted|
            obfuscate_env_vars(decrypted)
          end
        end

        def obfuscate_env_vars(vars)
          case vars
          when Hash
            vars.map { |key, var| [key, obfuscate_env_vars(var)] }.to_h
          when String
            vars =~ ENV_VAR_PATTERN ? vars.gsub(ENV_VAR_PATTERN) { |*| '[secure]' } : '[secure]'
          else
            '[One of the secure variables in your .travis.yml has an invalid format.]'
          end
        end

        def secure
          @secure ||= SecureConfig.new(key)
        end
    end
  end
end
