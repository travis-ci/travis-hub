require 'thread'
require 'hubble'
require 'active_support/core_ext/class/attribute'

module Travis
  class Hub
    class ErrorReporter
      class_attribute :queue
      attr_accessor :thread
      self.queue = Queue.new

      def run
        @thread = Thread.new &method(:error_loop)
      end

      def error_loop
        loop &method(:pop)
      end

      def pop
        begin
          handle(queue.pop)
        rescue => e
          puts "Error handling error: #{e.message}"
        end
      end

      def handle(error)
        Hubble.report(error, error_metadata(error))
        Travis.logger.error("Hub error: #{error.message}")
      end

      def error_metadata(error)
        metadata = {}
        metadata["payload"] = error.payload if error.respond_to?(:payload)
        metadata["event"] = error.event if error.respond_to?(:event)
        metadata["env"] = Travis.env
        metadata
      end

      def self.enqueue(error)
        queue.push(error)
      end
    end
  end
end
