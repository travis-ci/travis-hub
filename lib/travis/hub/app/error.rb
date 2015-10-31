require 'forwardable'

module Travis
  module Hub
    class App
      class Error < StandardError
        extend Forwardable

        def_delegators :exception, :message, :backtrace, :class

        attr_reader :exception, :event, :params

        def initialize(exception, event, params)
          @exception = exception
          @event = event
          @params = params
        end

        def metadata
          { event: event, payload: payload }
        end
      end
    end
  end
end
