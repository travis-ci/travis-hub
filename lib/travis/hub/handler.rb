require 'travis/hub/helper/context'
require 'travis/hub/helper/string'
require 'travis/hub/service'

module Travis
  module Hub
    class Handler
      include Helper::Context, Helper::String

      attr_reader :context, :type, :event, :payload, :object

      def initialize(context, event, payload)
        @context = context
        @type, @event = parse_event(event)
        @payload = normalize_payload(payload)
      end

      def run
        with_active_record do
          time do
            handle
          end
        end
      end

      private

        def handle
          const = Service.const_get("Update#{camelize(type)}")
          const.new(context, event, payload).run
        end

        def parse_event(event)
          parts = normalize_event(event).split(':')
          unknown_event(event) unless parts.size == 2
          parts.map(&:to_sym)
        end

        def normalize_event(event)
          event.to_s.gsub(':test', '') # TODO is anyone still sending these?
        end

        def normalize_payload(payload)
          payload = payload.symbolize_keys
          payload = normalize_state(payload)
          normalize_timestamps(payload)
        end

        def normalize_state(payload)
          payload.delete(:state)       if payload[:state] == 'reset'
          payload[:state] = 'canceled' if payload[:state] == 'cancelled'
          payload
        end

        def normalize_timestamps(payload)
          payload = payload.reject { |key, value| key.to_s =~ /_at$/ && value.to_s.include?('0001') }
          queued_at, received_at = payload.values_at(:queued_at, :received_at)
          payload[:received_at] = queued_at if queued_at && received_at && queued_at > received_at
          payload
        end

        def unknown_event(event)
          fail("Cannot parse event: #{event.inspect}. Must have the format [type]:[event], e.g. job:start")
        end

        def time
          started_at = Time.now
          yield.tap do
            options = { started_at: started_at, finished_at: Time.now }
            meter("hub.handle", options)
            meter("hub.handle.#{type}", options)
            meter("hub.handle.#{type}.#{event}", options)
          end
        end

        def with_active_record(&block)
          ActiveRecord::Base.connection_pool.with_connection do
            Log.connection_pool.with_connection do
              Log::Part.connection_pool.with_connection(&block)
            end
          end
        rescue ActiveRecord::ActiveRecordError => e
          count ||= 0
          raise e if count > 10
          count += 1
          error "ActiveRecord::ConnectionTimeoutError while processing a message. Retrying #{count}/10."
          meter 'hub.exceptions.active_record'
          sleep 1
          puts e.message, e.backtrace
          retry
        end
    end
  end
end
