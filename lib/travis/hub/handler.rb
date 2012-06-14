require 'hashr'

module Travis
  class Hub
    class Handler
      autoload :Job,     'travis/hub/handler/job'
      autoload :Request, 'travis/hub/handler/request'
      autoload :Worker,  'travis/hub/handler/worker'

      include Logging
      extend  Instrumentation, NewRelic

      class << self
        def handle(event, payload)
          self.for(event, payload).handle
        end

        def for(event, payload)
          case event_type(event, payload)
          when /^request/
            Handler::Request.new(event, payload)
          when /^job/
            Handler::Job.new(event, payload)
          when /^worker/
            Handler::Worker.new(event, payload)
          when /^sync/
            Handler::Sync.new(event, payload)
          else
            raise "Unknown message type: #{event.inspect}"
          end
        end

        def event_type(event, payload)
          (event || extract_event(payload)).to_s
        end

        def extract_event(payload)
          warn "Had to extract event from payload: #{payload.inspect}"
          case payload['type']
          when 'pull_request', 'push'
            'request'
          else
            payload['type']
          end
        end
      end

      attr_accessor :event, :payload

      def initialize(event, payload)
        @event = event
        @payload = normalize(payload)
      end

      private

        def normalize(payload)
          case payload
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
