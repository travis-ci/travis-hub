module Travis
  module Services
    module Registry
      def add(key, const = nil)
        if key.is_a?(Hash)
          key.each { |key, const| add(key, const) }
        else
          services[key.to_sym] = const
        end
      end

      def [](key)
        services[key.to_sym] || raise("can not use unregistered service #{key}. known services are: #{services.keys.inspect}")
      end

      private

        def services
          @services ||= {}
        end
    end

    extend Registry

    class << self
      def register
        constants(false).each { |name| const_get(name) }
      end
    end
  end

  class << self
    def services=(services)
      @services = services
    end

    def services
      @services ||= Travis::Services
    end
  end
end

require 'travis/services/helpers'

module Travis
  extend Services::Helpers
end

require 'travis/services/base'
require 'travis/services/update_job'
