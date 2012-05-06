module Travis
  class Hub
    class Exception < StandardError

      attr_reader :event, :payload, :exception

      def initialize(event, payload, exception)
        @event = event
        @payload = payload
        @exception = exception
      end

      def message
        "env: #{Travis.env}\nevent: #{event.inspect}\npayload: #{payload.inspect}\n#{exception.message}"
      end

      def backtrace
        exception.backtrace
      end
    end
  end
end
