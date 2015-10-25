module Travis
  module Hub
    module App
      class Handler
        attr_reader :type, :event, :payload

        def initialize(type, payload)
          @type, @event = parse_type(type)
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
            Service.const_get("Update#{type.to_s.sub(/./) { |char| char.upcase }}")
          end

          def parse_type(type)
            parts = normalize_type(type).split(':')
            unknown_type(type) unless parts.size == 2
            parts.map(&:to_sym)
          end

          def normalize_type(type)
            type = type.to_s.gsub(':test', '')
            type = type.gsub('reset', 'restart') # TODO deprecate :reset
            type
          end

          def normalize_payload(payload)
            payload['state'] = nil        if payload['state'] == 'reset'
            payload['state'] = 'canceled' if payload['state'] == 'cancelled'
            payload
          end

          def unknown_type(type)
            fail("Cannot parse type: #{type.inspect}. Must have the format [type]:[event], e.g. job:start")
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
      end
    end
  end
end
