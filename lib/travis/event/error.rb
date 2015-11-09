require 'forwardable'

module Travis
  module Event
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
        { event: event, params: params }
      end

      def tags
        { app: :hub, context: :event }.merge(options[:tags] || {})
      end
    end
  end
end
