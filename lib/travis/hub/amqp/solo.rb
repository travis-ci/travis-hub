require 'travis/hub/amqp/queue'
require 'travis/hub/handler'
require 'travis/hub/helper/context'

module Travis
  module Hub
    class Amqp
      class Solo
        include Helper::Context

        attr_reader :context, :name, :count

        def initialize(context, name, options)
          @context = context
          @name = name
          @count  = options[:count] || 1
        end

        def run
          info "Using #{threads} threads on #{name}."
          threads.times { Thread.new { subscribe } }
          sleep
        end

        private

          def subscribe
            Queue.new(context, queue, &method(:handle)).subscribe
          end

          def handle(event, payload)
            Handler.new(context, event, payload).run
          end

          def queue
            config.queue
          end

          def threads
            config.threads
          end
      end
    end
  end
end
