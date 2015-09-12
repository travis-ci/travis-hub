require 'travis/hub/app/queue'
require 'travis/hub/service/update_build'
require 'travis/hub/service/update_job'

module Travis
  module Hub
    module App
      class Solo < Struct.new(:name)
        def run
          Queue.subscribe(queue, &method(:handle))
        end

        private

          def queue
            QUEUE
          end

          def handle(type, payload)
            with_active_record do
              handle_event(type, payload)
            end
          end

          def handle_event(type, payload)
            type, event = parse_type(type)
            event = :restart if event == :reset # TODO deprecate :reset
            time(type, event) do
              handler(type).new(event: event, data: payload).run
            end
          end

          def handler(type)
            Service.const_get("Update#{type.to_s.sub(/./) { |char| char.upcase }}")
          end

          def parse_type(type)
            parts = type.to_s.split(':')
            unknown_type(type) unless parts.size == 2
            parts.map(&:to_sym)
          end

          def unknown_type(type)
            fail("Cannot parse type: #{type.inspect}. Must have the format [type]:[event], e.g. job:start")
          end

          def time(type, event, &block)
            Metriks.timer("hub.#{name}.handle.#{type}").time do
              Metriks.timer("hub.#{name}.handle.#{type}.#{event}", &block)
            end
          end

          def with_active_record(&block)
            ActiveRecord::Base.connection_pool.with_connection do
              ActiveRecord::Base.cache(&block)
            end
          end
      end
    end
  end
end
