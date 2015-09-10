require 'travis/config'

module Travis
  module Hub
    class Config < Travis::Config
      define  amqp:          { username: 'guest', password: 'guest', host: 'localhost', prefetch: 1 },
              database:      { adapter: 'postgresql', database: "travis_#{env}", encoding: 'unicode', min_messages: 'warning', pool: 25 },
              redis:         { url: 'redis://localhost:6379' },
              sidekiq:       { namespace: 'sidekiq', pool_size: 1 },
              lock:          { strategy: :postgresql, transactional: false, timeout: 5 },
              # lock:          { strategy: :redis },
              states_cache:  { memcached_servers: 'localhost:11211' },

              host:          'travis-ci.org',
              encryption:    env == 'development' || env == 'test' ? { key: 'secret' * 10 } : {},
              logger:        { thread_id: true },
              metrics:       { reporter: 'librato' },
              notifications: [], # TODO rename to event.handlers
              repository:    { ssl_key: { size: 4096 } }

              # tokens:        { internal: 'token' },
              # auth:          { target_origin: nil },
              # assets:        { host: HOSTS[env.to_sym] },
              # s3:            { access_key_id: '', secret_access_key: '' },
              # pusher:        { app_id: 'app-id', key: 'key', secret: 'secret' },
              # smtp:          {},
              # email:         {},
              # github:        { api_url: 'https://api.github.com', token: 'travisbot-token' },
              # async:         {},
              # queues:        [],
              # default_queue: 'builds.linux',
              # jobs:          { retry: { after: 60 * 60 * 2, max_attempts: 1, interval: 60 * 5 } },
              # queue:         { limit: { default: 5, by_owner: {} }, interval: 3 },
              # logs:          { shards: 1, intervals: { vacuum: 10, regular: 180, force: 3 * 60 * 60 } },
              # email:         {},
              # roles:         {},
              # archive:       {},
              # ssl:           {},
              # repository_filter: { include: [/^rails\/rails/], exclude: [/\/rails$/] },
              # sync:          { organizations: { repositories_limit: 1000 } },
              # sentry:        { },
              # services:      { find_requests: { max_limit: 100, default_limit: 25 } },
              # settings:      { timeouts: { defaults: { hard_limit: 50, log_silence: 10 }, maximums: { hard_limit: 180, log_silence: 60 } } },
              # endpoints:     { }

      default :_access => [:key]

      def logs_database
        super || database
      end
    end
  end
end
