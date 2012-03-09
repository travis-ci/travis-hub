require 'thread'
require 'hubble'

module Travis
  class Hub
    class ErrorReporter
      attr_reader :queue, :thread

      def initialize
        @queue = Queue.new
      end

      def run
        @thread = Thread.new &method(:error_loop)
      end

      def error_loop
        loop &method(:pop)
      end

      def pop
        begin
          error = @queue.pop
          Hubble.report(error)
        rescue => e
          puts "Error handling error: #{e.message}"
        end
      end
    end
  end
end
