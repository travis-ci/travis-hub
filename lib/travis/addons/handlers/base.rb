require 'travis/event/handler'
require 'travis/addons/config'
require 'travis/addons/helpers'
require 'travis/addons/instrument'
require 'travis/addons/serializer/generic/job'
require 'travis/addons/serializer/generic/build'

module Travis
  module Addons
    module Handlers
      class Base < Event::Handler
        include Helpers

        def event
          # TODO can this be moved to clients?
          super == :restarted ? :created : super
        end

        def data
          @data ||= Serializer::Generic.const_get(object_type.camelize).new(object).data
        end
        alias payload data

        def config
          @config ||= Config.new(data, secure_key)
        end

        def repository
          object.repository
        end

        def request
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
      end
    end
  end
end
