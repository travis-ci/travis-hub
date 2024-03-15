require 'sidekiq/pro/expiry'

module Travis
  module Sidekiq
    extend self

    def hub(*args)
      default_client.push(
        'queue' => 'hub',
        'class' => 'Travis::Hub::Sidekiq::Worker',
        'args' => args.map! { |arg| arg.to_json }
      )
    end

    def scheduler(*args)
      default_client.push(
        'queue' => ENV['SCHEDULER_SIDEKIQ_QUEUE'] || 'scheduler',
        'class' => 'Travis::Scheduler::Worker',
        'args' => [:event, *args].map! { |arg| arg.to_json }
      )
    end

    def tasks(queue, *args)
      default_client.push(
        'queue' => ENV['TASKS_SIDEKIQ_QUEUE'] || queue.to_s,
        'class' => 'Travis::Tasks::Worker',
        'args' => [nil, "Travis::Addons::#{queue.to_s.camelize}::Task", 'perform', *args].map! { |arg| arg.to_json }
      )
    end

    def live(*args)
      default_client.push(
        'queue' => 'pusher-live',
        'class' => 'Travis::Async::Sidekiq::Worker',
        'args' => [nil, 'Travis::Addons::Pusher::Task', 'perform', *args].map! { |arg| arg.to_json }
      )
    end

    def insights(event, data)
      insights_client.push(
        'queue' => ENV['INSIGHTS_SIDEKIQ_QUEUE'] || 'insights',
        'class' => 'Travis::Insights::Worker',
        'args' => [:event, { event:, data: }].map! { |arg| arg.to_json },
        'dead' => false
      )
    end

    def logsearch(*args)
      default_client.push(
        'queue' => ENV['LOGSEARCH_SIDEKIQ_QUEUE'] || 'logsearch',
        'class' => 'Travis::LogSearch::Worker',
        'args' => args.map! { |arg| arg.to_json },
        'at' => Time.now.to_f + (ENV['LOGSEARCH_SIDEKIQ_DELAY']&.to_i || 60)
      )
    end

    def billing(*args)
      default_client.push(
        'queue' => 'billing',
        'class' => 'Travis::Billing::Worker',
        'args' => [nil, 'Travis::Billing::Services::UsageTracker', 'perform', *args].map! { |arg| arg.to_json }
      )
    end

    def billing(*args)
      default_client.push(
        'queue' => 'billing',
        'class' => 'Travis::Billing::Worker',
        'args'  => [nil, "Travis::Billing::Services::UsageTracker", 'perform', *args]
      )
    end

    private

    def default_client
      @default_client ||= ::Sidekiq::Client.new(pool: default_pool)
    end

    def default_pool
      ::Sidekiq::RedisConnection.create(
        url: config.redis.url,
        id: nil
      )
    end

    def insights_client
      @insights_client ||= if ENV['INSIGHTS_REDIS_ENABLED'] == 'true'
                             ::Sidekiq::Client.new(insights_pool)
                           else
                             default_client
                           end
    end

    def insights_pool
      ::Sidekiq::RedisConnection.create(
        url: config.redis_insights.url
      )
    end

    def config
      @config ||= Travis::Hub::Config.load
    end
  end
end
