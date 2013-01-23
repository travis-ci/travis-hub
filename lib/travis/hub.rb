require 'multi_json'

require 'travis'
require 'core_ext/kernel/run_periodically'

$stdout.sync = true

module Travis
  class Hub
    autoload :Error, 'travis/hub/error'
    autoload :Queue, 'travis/hub/queue'

    extend Instrumentation

    def setup
      Travis::Async.enabled = true
      Travis::Amqp.config = Travis.config.amqp

      Travis::Database.connect
      Travis::Async::Sidekiq.setup(Travis.config.redis.url, Travis.config.sidekiq)

      Travis::Exceptions::Reporter.start
      Travis::Notification.setup
      Travis::Addons.register

      Travis::Memory.new(:hub).report_periodically if Travis.env == 'production'
      NewRelic.start if File.exists?('config/newrelic.yml')

      # do we still need these in hub?
      # Travis::Mailer.setup
      # GH::DefaultStack.options[:ssl] = Travis.config.ssl
    end

    def run
      enqueue_jobs
      Queue.subscribe(&method(:handle))
    end

    private

      def handle(event, payload)
        ActiveRecord::Base.cache do
          Travis.run_service(:update_job, event: event.to_s.split(':').last, data: payload)
        end
      end

      def enqueue_jobs
        run_periodically(Travis.config.queue.interval) do
          Travis.run_service(:enqueue_jobs) unless Travis::Features.feature_active?(:travis_enqueue)
        end
      end

      # class Instrument < Travis::Notification::Instrument
      #   def update_completed
      #     publish(msg: %(for #<Job id="#{target.payload['id']}">), event: target.event, payload: target.payload)
      #   end
      # end
      # Instrument.attach_to(self)
  end
end
