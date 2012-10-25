require 'multi_json'
require 'benchmark'
require 'active_support/core_ext/float/rounding'
require 'core_ext/kernel/run_periodically'
require 'core_ext/hash/compact'

require 'travis'
require 'travis/support'

$stdout.sync = true

module Travis
  class Hub
    autoload :Handler,    'travis/hub/handler'
    autoload :Instrument, 'travis/hub/instrument'
    autoload :Error,      'travis/hub/error'
    autoload :Queues,     'travis/hub/queues'

    include Logging

    class << self
      def start
        setup
        prune_workers
        Travis::Hub::Queues.subscribe
      end

      protected

        def setup
          Travis::Features.start

          Travis::Async.enabled = true
          Travis::Amqp.config = Travis.config.amqp
          Travis.services = Travis::Services
          GH::DefaultStack.options[:ssl] = Travis.config.ssl

          Travis.config.update_periodically
          Travis::Memory.new(:hub).report_periodically if Travis.env == 'production'

          Travis::Exceptions::Reporter.start
          Travis::Notification.setup

          Travis::Database.connect
          Travis::Mailer.setup
          Travis::Async::Sidekiq.setup(Travis.config.redis.url, Travis.config.sidekiq)

          NewRelic.start if File.exists?('config/newrelic.yml')
        end

        def prune_workers
          run_periodically(Travis.config.workers.prune.interval, &::Worker.method(:prune))
        end

        # def cleanup_jobs
        #   run_periodically(Travis.config.jobs.retry.interval, &::Job.method(:cleanup))
        # end
    end
  end
end
