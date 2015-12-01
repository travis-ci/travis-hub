require 'forwardable'

module Travis
  module Hub
    class Amqp
      class Error < StandardError
        extend Forwardable

        def_delegators :exception, :message, :backtrace, :class

        attr_reader :exception, :event, :payload, :options

        def initialize(exception, event, payload, options = {})
          @exception = exception
          @event = event
          @payload = payload
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
