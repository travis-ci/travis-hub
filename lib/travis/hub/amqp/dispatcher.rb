require 'travis/hub/amqp/queue'
require 'travis/hub/amqp/solo'
require 'travis/hub/helper/context'
require 'travis/hub/support/reroute'

module Travis
  module Hub
    class Amqp
      class Dispatcher
        include Helper::Context

        attr_reader :context, :count

        def initialize(context, _, options)
          @context = context
          @count = options[:count] || 1
        end

        def run
          Queue.new(context, queue, &method(:handle)).subscribe
        end

        private

          def handle(event, payload)
            with_active_record do
              job = ::Job.find(payload.fetch('id'))
              # key = reroute?(job) ? :next : job.source_id % count + 1
              key = job.source_id % count + 1
              puts "Routing #{event} for <Job id=#{job.id}> to #{queue_for(key)}."
              publish(key, event, payload)
            end
          end

          def publish(key, event, payload)
            context.amqp.publish(queue_for(key), event, payload.merge(worker_count: count))
            meter("hub.dispatcher.delegate.#{key}")
          end

          # def reroute?(job)
          #   Reroute.new(:hub_next, id: job.id, owner_name: job.repository.owner_name).reroute?
          # end

          def queue_for(num)
            "#{queue}.#{num}"
          end

          def queue
            config.queue
          end

          def with_active_record(&block)
            Job.connection_pool.with_connection(&block)
          end
      end
    end
  end
end
