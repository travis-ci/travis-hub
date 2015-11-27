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

          def queue
            config.queue
          end

          def threads
            config.threads
          end

          def handle(type, payload)
          end
      end
    end
  end
end
