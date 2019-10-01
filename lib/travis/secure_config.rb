require 'base64'

module Travis
  # Decrypts a single configuration value from a configuration file using the
  # repository's SSL key.
  #
  # This is used so people can add encrypted sensitive data to their
  # `.travis.yml` file.
  class SecureConfig < Struct.new(:key)
    require 'travis/secure_config/obfuscate'

    MSGS = {
      decrypt_failed: 'Error decrypting config value for %s: %s'
    }

    class << self
      def decrypt(config, key)
        new(key).decrypt(config)
      end

      def encrypt(config, key)
        new(key).encrypt(config)
      end

      def obfuscate(config, key)
        Obfuscate.new(config, key).run
      end
    end

    def decrypt(config, &block)
      return config if config.nil? || config.is_a?(String)

      config.inject(config.class.new) do |result, element|
        key, element = element if result.is_a?(Hash)
        value = process(result, key, decrypt_element(key, element, &block))
      end
    end

    def encrypt(config)
      { 'secure' => key.encode(config) }
    end

    def obfuscate(config)
    end

    private

      def decrypt_element(key, element, &block)
        if element.is_a?(Array) || element.is_a?(Hash)
          decrypt(element, &block)
        elsif secure_key?(key) && element
          value = decrypt_value(element)
          block ? yield(value) : value
        else
          element
        end
      end

      def process(result, key, value)
        if result.is_a?(Array)
          result << value
        elsif result.is_a?(Hash) && !secure_key?(key)
          result[key] = value
          result
        else
          value
        end
      end

      def decrypt_value(value)
        # TODO should probably be checked earlier
        raise unless key.respond_to?(:decrypt)
        decoded = Base64.decode64(value)
        result = key.decrypt(decoded)
        result || raise
      rescue => e
        decrypt_failed(value)
        nil
      end

      def decrypt_failed(value)
        # TODO make this an exception on the level :warning
        Travis::Addons.logger.error(MSGS[:decrypt_failed] % [self.key.try(:repository).try(:slug), value])
      end

      def secure_key?(key)
        key && (key == :secure || key == 'secure')
      end
  end
end
