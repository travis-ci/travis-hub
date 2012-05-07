require 'hashr'

module Travis
  class Hub
    class Handler
      autoload :Configure, 'travis/hub/handler/configure'
      autoload :Job,       'travis/hub/handler/job'
      autoload :Request,   'travis/hub/handler/request'
      autoload :Worker,    'travis/hub/handler/worker'

      include Logging

      class << self
        def for(event, payload)
          case extract_event_type(event, payload)
          when /^request/
            Handler::Request.new(event, payload)
          when /^configure/
            Handler::Configure.new(event, payload)
          when /^job/
            Handler::Job.new(event, payload)
          when /^worker/
            Handler::Worker.new(event, payload)
          else
            raise "Unknown message type: #{event.inspect}"
          end
        end

        def extract_event_type(event, payload)
          (event || payload["type"]).to_s
        end
      end

      attr_accessor :event, :payload

      def initialize(event, payload)
        @event = event
        @payload = case payload
          when Hash
            Hashr.new(payload)
          when Array
            payload.map { |hash| Hashr.new(hash) }
          else
            payload
        end
      end
    end
  end
end
