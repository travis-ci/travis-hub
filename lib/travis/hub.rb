require 'multi_json'
require 'hashr'
require 'benchmark'
require 'hubble'
require 'metriks'
require 'metriks/reporter/logger'
require 'active_support/core_ext/float/rounding.rb'
require 'core_ext/module/include'
require 'core_ext/kernel/run_periodically'

require 'travis'
require 'travis/support'

# Order of inclusion matters: async must be included last
require 'travis/hub/instrumentation'
require 'travis/hub/async'

$stdout.sync = true

module Travis
  class Hub
    autoload :Handler,       'travis/hub/handler'
    autoload :Error,         'travis/hub/error'
    autoload :ErrorReporter, 'travis/hub/error_reporter'
    autoload :NewRelic,      'travis/hub/new_relic'
    autoload :Metrics,       'travis/hub/metrics'
    autoload :Queues,        'travis/hub/queues'

    include Logging

    class << self
      def start
        setup
        prune_workers
        Travis::Hub::Queues.subscribe
      end

      protected

        def setup
          Travis.config.update_periodically

          GH::DefaultStack.options[:ssl] = {
            :ca_path => Travis.config.ssl.ca_file,
            :ca_file => Travis.config.ssl.ca_file
          }

          start_monitoring
          Database.connect
          Travis::Mailer.setup
          Travis::Features.start
          Travis::Amqp.config = Travis.config.amqp
        end

        def start_monitoring
          Hubble.setup if ENV['HUBBLE_ENV']
          Travis::Hub::ErrorReporter.new.run
          Travis::Hub::Metrics.setup_subscriptions
          Metriks::Reporter::Logger.new.start
          NewRelic.start if File.exists?('config/newrelic.yml')
        end

        def prune_workers
          run_periodically(Travis.config.workers.prune.interval, &::Worker.method(:prune))
        end

        def cleanup_jobs
          run_periodically(Travis.config.jobs.retry.interval, &::Job.method(:cleanup))
        end
    end
  end
end
