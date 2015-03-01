require 'travis/support/logging'
require 'travis/support/retryable'

module Travis
  module Hub
    class Solo
      include Travis::Logging
      include Travis::Retryable

      DEFAULT_SUBSCRIBER_COUNT = 2

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

      attr_accessor :name, :count
      def initialize(name, count = nil)
        @name  = name
        @count = count ? Integer count[/\d+/] : DEFAULT_SUBSCRIBER_COUNT
      end

      def run
        enqueue_jobs
        subscribe_to_queue
      end

      private

        def subscribe_to_queue
          1.upto(count) do |num|
            Queue.subscribe(queue, &method(:handle))
          end
        end

        def queue
          'builds'
        end

        def handle(event, payload)
          retryable(tries: 5) do
            Metriks.timer("hub.#{name}.handle").time do
              ActiveRecord::Base.connection.begin_db_transaction
              ActiveRecord::Base.connection.execute('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE')
              ActiveRecord::Base.cache do
                handle_event(event, payload)
              end
              ActiveRecord::Base.connection.commit_db_transaction
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
