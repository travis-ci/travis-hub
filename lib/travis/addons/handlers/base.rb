require 'travis/event/handler'
require 'travis/addons/config'
require 'travis/addons/helpers/coder'
require 'travis/addons/instrument'
require 'travis/addons/serializer/tasks/build'

module Travis
  module Addons
    module Handlers
      class Base < Event::Handler
        include Helpers::Coder

        def event
          # TODO can this be moved to clients?
          super.to_s.gsub('restarted', 'created')
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

        def pull_request?
          object.pull_request?
        end

        def enabled?
          pull_request? ? on_pull_request? : true
        end

        def on_pull_request?
          config.key?(:on_pull_requests) ? !!config[:on_pull_requests] : true
        end
      end
    end
  end
end
