require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Notifiers < Base
        include Handlers::Task

        def handle?
          handlers.any?
        end

        def handle
          handlers.each do |handler|
            handler.class.notify(handler.event, handler.params)
          end
        end

        def handlers
          @handlers ||= configs.map { |config| handler(config) }.select(&:handle?)
        end

        def handler(config)
          const = self.class.const_get(:Notifier)
          const.new(event, params.merge(config: config))
        end

        def configs
          @configs ||= begin
            config = object.config.fetch(:notifications, {})
            config = config.is_a?(Hash) ? config.fetch(key, {}) : config
            wrap(decrypt(config))
          end
        end

        def key
          self.class::KEY
        end

        def decrypt(config)
          return config unless config.is_a?(Hash) || config.is_a?(String)
          Travis::SecureConfig.decrypt(config, secure_key)
        end

        def secure_key
          repository.key if respond_to?(:repository)
        end

        def wrap(obj)
          obj.is_a?(Array) ? obj : [obj]
        end
      end

      class Notifier < Base
        include Handlers::Task

        def config
          @config ||= Config.new(object, params[:config])
        end
      end
    end
  end
end
