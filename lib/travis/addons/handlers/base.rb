require 'travis/event/handler'
require 'travis/addons/config'
require 'travis/addons/helpers/task'
require 'travis/addons/instrument'
require 'travis/addons/serializer/generic/job'
require 'travis/addons/serializer/generic/build'

module Travis
  module Addons
    module Handlers
      class Base < Event::Handler
        include Helpers::Task

        def event
          # TODO can this be moved to clients?
          super.to_s.gsub('restarted', 'created')
        end

        def data
          @data ||= Serializer::Generic.const_get(object_type.camelize).new(object).data
        end

        def payload
          Travis::SecureConfig.decrypt(data, secure_key)
        end

        def config
          @config ||= Config.new(data, secure_key)
        end

        def repository
          object.repository
        end

        def request
          ::Travis::Addons.logger.info "object in base is #{object.inspect}"
          object.request
        end

        def commit
          object.commit
        end

        def secure_key
          object.repository.key if object.respond_to?(:repository)
        end

        def pull_request?
          object.pull_request?
        end

        def enabled?(notifier)
          sym = notifier.to_sym
          pull_request? ? on_pull_request?(sym) : true
        end

        def on_pull_request?(sym)
          value = config.values(sym, :on_pull_requests)
          value.nil? || value
        end
      end
    end
  end
end
