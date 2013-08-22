module Travis
  module Hub
    class Solo
      def setup
        Travis::Async.enabled = true
        Travis::Amqp.config = Travis.config.amqp
        GH::DefaultStack.options[:ssl] = Travis.config.ssl

        Travis::Database.connect
        if Travis.config.logs_database
          Log.establish_connection 'logs_database'
          Log::Part.establish_connection 'logs_database'
        end

        Travis::Async::Sidekiq.setup(Travis.config.redis.url, Travis.config.sidekiq)

        Travis::Exceptions::Reporter.start
        Travis::Notification.setup
        Travis::Addons.register

        Travis::Memory.new(:hub).report_periodically if Travis.env == 'production' && Travis.config.metrics.report
        NewRelic.start if File.exists?('config/newrelic.yml')
      end

      attr_accessor :name, :count, :number
      def initialize(name, count = nil, number = nil)
        @name   = name
        @count  = Integer count[/\d+/]  if count
        @number = Integer number[/\d+/] if number
      end

      def run
        enqueue_jobs
        Queue.subscribe(queue, &method(:handle))
      end

      private

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
          Travis.run_service(:enqueue_jobs) unless Travis::Features.feature_active?(:travis_enqueue)
        rescue => e
          Travis.logger.log_exception(e)
        end
    end
  end
end
