require 'travis/hub/helper/context'
require 'travis/hub/helper/string'
require 'travis/hub/service'
require 'travis/hub/support/reroute'

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
            reroute or handle
          end
        end
      end

      private

        def reroute
          Reroute.new(context, type, event, payload).run
        end

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
          event = event.to_s.gsub(':test', '')
          event = event.gsub('reset', 'restart') # TODO deprecate :reset
          event
        end

        def normalize_payload(payload)
          payload = payload.symbolize_keys
          payload.delete(:state)       if payload[:state] == 'reset'
          payload[:state] = 'canceled' if payload[:state] == 'cancelled'
          payload
        end

        def unknown_event(event)
          fail("Cannot parse event: #{event.inspect}. Must have the format [type]:[event], e.g. job:start")
        end

        def time
          started_at = Time.now
          yield
          options = { started_at: started_at, finished_at: Time.now }
          meter("hub.handle", options)
          meter("hub.handle.#{type}", options)
          meter("hub.handle.#{type}.#{event}", options)
        end

        def with_active_record(&block)
          ActiveRecord::Base.connection_pool.with_connection do
            Log.connection_pool.with_connection do
              Log::Part.connection_pool.with_connection(&block)
            end
          end
        rescue ActiveRecord::ActiveRecordError => e
          count ||= 0
          raise e if count += 1 > 10
          error "ActiveRecord::ConnectionTimeoutError while processing a message. Retrying #{count}/10."
          meter 'hub.exceptions.active_record'
          sleep 1
          puts e.message, e.backtrace
          retry
        end
    end
  end
end
