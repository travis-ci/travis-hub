require 'forwardable'

module Travis
  module Hub
    class App
      class Error < StandardError
        extend Forwardable

        def_delegators :exception, :message, :backtrace, :class

        attr_reader :exception, :event, :params, :options

        def initialize(exception, event, params, options = {})
          @exception = exception
          @event = event
          @params = params
          @options = options
        end

        def level
          options[:level] || :error
        end

        def data
          { event: event, payload: payload }
        end

        def tags
          { app: :hub, context: :app }.merge(options[:tags] || {})
        end
      end
    end
  end
end
