require 'travis/config'

module Travis
  module Hub
    class Config < Travis::Config
      define amqp:          { username: 'guest', password: 'guest', host: 'localhost', prefetch: 1 },
             database:      { adapter: 'postgresql', database: "travis_#{env}", encoding: 'unicode', min_messages: 'warning', pool: 25 },
             redis:         { url: 'redis://localhost:6379' },
             sidekiq:       { namespace: 'sidekiq', pool_size: 1 },
             lock:          { strategy: :postgresql, try: true, transactional: false, timeout: 30 },
             states_cache:  { memcached_servers: 'localhost:11211' },

             host:          'travis-ci.org',
             encryption:    env == 'development' || env == 'test' ? { key: 'secret' * 10 } : {},
             logger:        { thread_id: true },
             metrics:       { reporter: 'librato' },
             notifications: [],
             repository:    { ssl_key: { size: 4096 } }

      def logs_database
        super || database
      end
    end
  end
end
