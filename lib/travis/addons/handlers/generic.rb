require 'travis/event/handler'
require 'travis/addons/config'
require 'travis/addons/helpers'
require 'travis/addons/instrument'
require 'travis/addons/serializer/generic/job'
require 'travis/addons/serializer/generic/build'

module Travis
  module Addons
    module Handlers
      class Generic < Event::Handler
        include Helpers

        attr_reader :payload, :config

        def initialize(*)
          super
          @payload = Serializer::Generic.const_get(object_type.camelize).new(object).data
          @config  = Config.new(@payload, secure_key)
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
