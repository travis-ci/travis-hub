require 'travis/hub/app/queue'
require 'travis/hub/helper/context'
require 'travis/hub/service/update_build'
require 'travis/hub/service/update_job'

module Travis
  module Hub
    class App
      class Solo
        include Helper::Context

        THREADS = 2
        QUEUE = 'builds'

        attr_reader :context, :name, :count

        def initialize(context, name, options)
          @context = context
          @name = name
          @count  = options[:count] || 1
        end

        def run
          THREADS.times { Thread.new { subscribe } }
          sleep
        end

        private

          def subscribe
            Queue.new(context, queue, &method(:handle)).subscribe
          end

          def queue
            ENV['QUEUE'] || QUEUE
          end

          def handle(type, payload)
            type, event = parse_type(type)
            with_active_record do
              time(type, event) do
                payload = normalize_payload(payload)
                # event = :cancel if payload[:state].to_s == 'canceled' # wtf.
                handler(type).new(context, event, payload).run
              end
            end
          end

          def handler(type)
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
            payload = payload.symbolize_keys
            payload.delete(:state)       if payload[:state] == 'reset'
            payload[:state] = 'canceled' if payload[:state] == 'cancelled'
            payload
          end

          def unknown_type(type)
            fail "Cannot parse type: #{type.inspect}. Must have the format [type]:[event], e.g. job:start"
          end

          def time(type, event, &block)
            started_at = Time.now
            yield
            options = { started_at: started_at, finished_at: Time.now }
            meter("hub.#{name}.handle", options)
            meter("hub.#{name}.handle.#{type}", options)
            meter("hub.#{name}.handle.#{type}.#{event}", options)
          end

          def with_active_record(&block)
            ActiveRecord::Base.connection_pool.with_connection do
              Log.connection_pool.with_connection do
                Log::Part.connection_pool.with_connection(&block)
              end
            end
          rescue ActiveRecord::ActiveRecordError => e
          # rescue ActiveRecord::ConnectionTimeoutError, ActiveRecord::StatementInvalid => e
            count ||= 0
            raise e if count > 10
            count += 1
            error "ActiveRecord::ConnectionTimeoutError while processing a message. Retrying #{count}/10."
            sleep 1
            puts e.message, e.backtrace
            retry
          end
      end
    end
  end
end
