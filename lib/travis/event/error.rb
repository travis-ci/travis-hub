require 'forwardable'

module Travis
  module Event
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
        { event: event, params: params }
      end
    end
  end
end
