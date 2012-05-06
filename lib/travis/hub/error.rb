module Travis
  class Hub
    class Error < StandardError
      attr_reader :properties, :payload, :exception

      def initialize(properties, payload, exception)
        @properties = properties
        @payload = payload
        @exception = exception
      end

      def message
        "env: #{Travis.env}\nmessage: #{properties.inspect}\npayload: #{payload.inspect}\n#{exception.message}"
      end

      def backtrace
        exception.backtrace
      end
    end
  end
end
