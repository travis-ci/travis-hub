require 'travis/support/logging'

module Travis
  module Hub
    class Solo
      include Travis::Logging

      def setup
        Travis::Async.enabled = true
        Travis::Amqp.config = Travis.config.amqp

        Travis::Database.connect
        if Travis.config.logs_database
          Log.establish_connection 'logs_database'
          Log::Part.establish_connection 'logs_database'
        end

        Travis::Async::Sidekiq.setup(Travis.config.redis.url, Travis.config.sidekiq)

        Travis::Exceptions::Reporter.start
        Travis::Metrics.setup
        Travis::Notification.setup
        Travis::Addons.register

        declare_exchanges_and_queues
      end

      attr_accessor :name, :count, :number
      def initialize(name, count = nil, number = nil)
        @name   = name
        @count  = Integer count[/\d+/]  if count
        @number = Integer number[/\d+/] if number
      end

      def run
        enqueue_jobs
        subscribe_to_queue
      end

      private

        def subscribe_to_queue
          Queue.subscribe(queue, &method(:handle))
        end

        def queue
          'builds'
        end

        def handle(event, payload)
          Metriks.timer("hub.#{name}.handle").time do
            ActiveRecord::Base.cache do
              handle_event(event, payload)
            end
          end
        end

        def handle_event(event, payload)
          Travis.run_service(:update_job, event: event.to_s.split(':').last, data: payload)
        end

        def enqueue_jobs
          run_periodically(Travis.config.queue.interval) do
            Metriks.timer("hub.#{name}.enqueue_jobs").time { enqueue_jobs! }
          end
        end

        def enqueue_jobs!
          Travis.run_service(:enqueue_jobs)
        rescue => e
          log_exception(e)
        end

        def declare_exchanges_and_queues
          channel = Travis::Amqp.connection.create_channel
          channel.exchange 'reporting', durable: true, auto_delete: false, type: :topic
          channel.queue 'builds.linux', durable: true, exclusive: false
        end
    end
  end
end
