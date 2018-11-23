require 'sidekiq/pro/expiry'

module Travis
  module Sidekiq
    extend self

    def hub(*args)
      client.push(
        'queue' => 'hub',
        'class' => 'Travis::Hub::Sidekiq::Worker',
        'args'  => args
      )
    end

    def scheduler(*args)
      client.push(
        'queue' => ENV['SCHEDULER_SIDEKIQ_QUEUE'] || 'scheduler',
        'class' => 'Travis::Scheduler::Worker',
        'args'  => [:event, *args]
      )
    end

    def tasks(queue, *args)
      client.push(
        'queue'   => ENV['TASKS_SIDEKIQ_QUEUE'] || queue.to_s,
        'class'   => 'Travis::Tasks::Worker',
        'args'    => [nil, "Travis::Addons::#{queue.to_s.camelize}::Task", 'perform', *args]
      )
    end

    def live(*args)
      client.push(
        'queue'   => 'pusher-live',
        'class'   => 'Travis::Async::Sidekiq::Worker',
        'args'    => [nil, "Travis::Addons::Pusher::Task", 'perform', *args]
      )
    end

    def insights(event, data)
      client.push(
        'queue' => ENV['INSIGHTS_SIDEKIQ_QUEUE'] || 'insights',
        'class' => 'Travis::Insights::Worker',
        'args'  => [:event, { event: event, data: data }]
      )
    end

    def logsearch(*args)
      client.push(
        'queue' => ENV['LOGSEARCH_SIDEKIQ_QUEUE'] || 'logsearch',
        'class' => 'Travis::LogSearch::Worker',
        'args'  => args,
        'at'    => Time.now.to_f + (ENV['LOGSEARCH_SIDEKIQ_DELAY']&.to_i || 60)
      )
    end

    private

      def client
        @client ||= ::Sidekiq::Client.new(default_pool)
      end

      def default_pool
        ::Sidekiq::RedisConnection.create(
          url: config.redis.url,
          namespace: config.sidekiq.namespace,
          pool_size: config.sidekiq.pool_size
        )
      end

      def config
        @config ||= Travis::Hub::Config.load
      end
  end
end
