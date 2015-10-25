module Travis
  module Hub
    module App
      class Handler
        attr_reader :type, :event, :payload

        def initialize(event, payload)
          @type, @event = parse_event(event)
          @payload = normalize_payload(payload)
        end

        def handle
          with_active_record do
            meter do
              service.new(event: event, data: payload).run
            end
          end
        end

        private

          def service
            Service.const_get("Update#{camelize(type)}")
          end

          def parse_event(event)
            parts = normalize_event(event).split(':')
            unknown_event(event) unless parts.size == 2
            parts.map(&:to_sym)
          end

          def normalize_event(event)
            event = event.to_s.gsub(':test', '')
            event = event.gsub('reset', 'restart') # TODO deprecate :reset
            event
          end

          def normalize_payload(payload)
            payload['state'] = nil        if payload['state'] == 'reset'
            payload['state'] = 'canceled' if payload['state'] == 'cancelled'
            payload
          end

          def unknown_event(event)
            fail("Cannot parse event: #{event.inspect}. Must have the format [type]:[event], e.g. job:start")
          end

          def meter
            started_at = Time.now
            yield
            options = { started_at: started_at, finished_at: Time.now }
            Metrics.meter("hub.#{name}.handle.#{type}", options)
            Metrics.meter("hub.#{name}.handle.#{type}.#{event}", options)
          end

          def with_active_record(&block)
            ActiveRecord::Base.connection_pool.with_connection(&block)
          end

          def camelize(string)
            string.to_s.sub(/./) { |char| char.upcase }
          end
      end
    end
  end
end
