require 'travis/config'
require 'travis/config/heroku'

module Travis
  module Hub
    class Config < Travis::Config
      class << self
        def logs_api_url
          ENV['TRAVIS_HUB_LOGS_API_URL'] ||
            ENV['LOGS_API_URL'] ||
            'http://travis-logs-notset.example.com:1234'
        end

        def logs_api_auth_token
          ENV['TRAVIS_HUB_LOGS_API_AUTH_TOKEN'] ||
            ENV['LOGS_API_AUTH_TOKEN'] ||
            'notset'
        end
      end

      define amqp:          { username: 'guest', password: 'guest', host: 'localhost', prefetch: 1 },
             database:      { adapter: 'postgresql', database: "travis_#{env}", encoding: 'unicode', min_messages: 'warning', pool: 25, reaping_frequency: 60, variables: { statement_timeout: 10000 } },
             logs_api:      { url: logs_api_url, token: logs_api_auth_token },
             redis:         { url: 'redis://localhost:6379' },
             sidekiq:       { namespace: 'sidekiq', pool_size: 1 },
             lock:          { strategy: :redis },
             states_cache:  { memcached_servers: 'localhost:11211', memcached_options: {} },
             name:          'hub',
             host:          'travis-ci.org',
             encryption:    env == 'development' || env == 'test' ? { key: 'secret' * 10 } : {},
             logger:        { thread_id: true },
             librato:       {},
             metrics:       { reporter: 'librato' },
             repository:    { ssl_key: { size: 4096 } },
             queue:         'builds',
             limit:         { resets: { max: 50, after: 6 * 60 * 60 } },
             notifications: []

      def metrics
        # TODO cleanup keychain?
        super.to_h.merge(librato: librato.to_h.merge(source: librato_source), graphite: graphite)
      end

      def queue
        ENV['QUEUE'] || 'builds' # super
      end

      def threads
        ENV['THREADS'] ? ENV['THREADS'].to_i : 1
      end

      def librato_source
        ENV['LIBRATO_SOURCE'] || super
      end

      # # TODO legacy, upgrade travis-config
      # def states_cache
      #   super || { memcached_servers: memcached.servers, memcached_options: memcached.options }
      # end
    end
  end
end
