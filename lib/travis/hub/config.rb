require 'base64'
require 'hashr'
require 'travis/config'
require 'travis/config/heroku'

module Travis
  module Hub
    class Config < Travis::Config
      extend Hashr::Env

      class << self
        def http_basic_auth
          tokens = ENV['HTTP_BASIC_AUTH'] || ''
          tokens.split(',').map { |token| token.split(':').map(&:strip) }.to_h
        end

        def jwt_key(type)
          return unless key = ENV["JWT_RSA_#{type.upcase}_KEY"]
          key.starts_with?('--') ? key : Base64.decode64(key)
        end
      end

      define amqp:           { username: 'guest', password: 'guest', host: ENV['RABBITMQ_HOST'] || 'localhost', prefetch: 1 },
             database:       { adapter: 'postgresql', database: "travis_#{env}", encoding: 'unicode', min_messages: 'warning', pool: 25, reaping_frequency: 60, variables: { statement_timeout: 10000 } },
             logs_api:       { url: 'https://travis-logs-notset.example.com:1234', token: 'notset', retries: { max: 5, interval: 3, max_interval: 60, interval_randomness: 0.5, backoff_factor: 2 } },
             job_board:      { url: 'https://not:set@job-board.travis-ci.com', site: 'org' },
             redis:          { url: ENV['TRAVIS_REDIS_URL'] || 'redis://localhost:6379', insights_url: ENV['INSIGHTS_REDIS_URL'] || 'redis://localhost:6379' },
             sidekiq:        { namespace: 'sidekiq', pool_size: 1 },
             lock:           { strategy: :redis, ttl: 30000 },
             states_cache:   { memcached_servers: 'localhost:11211', memcached_options: {} },
             name:           'hub',
             host:           'travis-ci.org',
             encryption:     env == 'development' || env == 'test' ? { key: 'secret' * 10 } : {},
             logger:         { thread_id: true },
             librato:        {},
             sentry:         {},
             metrics:        { reporter: 'librato' },
             repository:     { ssl_key: { size: 4096 } },
             queue:          'builds',
             limit:          { resets: { max: 50, after: 6 * 60 * 60 } },
             notifications:  [ 'billing' ],
             auth:           { jwt_private_key: jwt_key(:private), jwt_public_key: jwt_key(:public), http_basic_auth: http_basic_auth },
             billing:        { url: ENV['BILLING_URL'] || 'http://localhost:9292', auth_key: ENV['BILLING_AUTH_KEY'] || 't0Ps3Cr3t' }

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
