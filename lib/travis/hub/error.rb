module Travis
  module Hub
    class Error < StandardError
      attr_reader :event, :payload, :exception

      def initialize(event, payload, exception)
        @event = event
        @payload = payload
        @exception = exception
      end

      def message
        exception.message
      end

      def backtrace
        exception.backtrace
      end

      def class
        exception.class
      end

      def metadata
        { 'payload' => payload, 'event' => event }
      end
    end
  end
end
