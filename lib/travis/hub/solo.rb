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

        Travis::Memory.new(:hub).report_periodically if Travis.env == 'production'
        NewRelic.start if File.exists?('config/newrelic.yml')
      end

      attr_accessor :count
      def initialize(argument = nil)
        @count = Integer(argument[/\d+/]) if argument
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
          ActiveRecord::Base.cache do
            handle_event(event, payload)
          end
        end

        def handle_event(event, payload)
          Travis.run_service(:update_job, event: event.to_s.split(':').last, data: payload)
        end

        def enqueue_jobs
          run_periodically(Travis.config.queue.interval) do
            begin
              Travis.run_service(:enqueue_jobs) unless Travis::Features.feature_active?(:travis_enqueue)
            rescue => e
              Travis.logger.log_exception(e)
            end
          end
        end
    end
  end
end