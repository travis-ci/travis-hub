require 'connection_pool'
require 'dalli'
require 'json'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/numeric/time'

# TODO extract

module Travis
  class << self
    attr_writer :states_cache

    def states_cache
      @states_cache ||= Travis::StatesCache.new
    end
  end

  class StatesCache
    class CacheError < StandardError; end

    attr_reader :adapter

    delegate :fetch, :to => :adapter

    def initialize(config, logger)
      @adapter = Memcached.new(config, logger)
    end

    def write(id, branch, data)
      data = { 'id' => data.id, 'state' => data.state.to_s } if data.respond_to?(:id)
      adapter.write(id, branch, data)
    end

    def fetch_state(id, branch)
      data = fetch(id, branch)
      data['state'].to_sym if data && data['state']
    end

    class Memcached
      attr_reader :logger, :pool
      attr_accessor :jitter
      attr_accessor :ttl

      def initialize(config, logger)
        @logger = logger
        @pool = ConnectionPool.new(:size => 10, :timeout => 3) do
          config[:client] || new_dalli_connection(config)
        end
        @jitter = 0.5
        @ttl = 7.days
      end

      def fetch(id, branch = nil)
        data = get(key(id, branch))
        data ? JSON.parse(data) : nil
      end

      def write(id, branch, data)
        build_id = data['id']
        data     = data.to_json

        logger.info("[states-cache] Caching states for repo_id=#{id} branch=#{branch} build_id=#{build_id}")
        set(key(id), data) if update?(id, nil, build_id)
        set(key(id, branch), data) if update?(id, branch, build_id)
      end

      def update?(id, branch, build_id)
        data = fetch(id, branch)

        if data
          last_id = data['id'].to_i
          stale   = build_id.to_i >= last_id
          logger.info(
            "[states-cache] cache is #{stale ? 'stale' : 'fresh' }: repo id=#{id} branch=#{branch}, " \
            "last cached build id=#{last_id}, checked build id=#{build_id}"
          )
          stale
        else
          logger.info(
            "[states-cache] cache does not exist: repo id=#{id} branch=#{branch}, " \
            "checked build id=#{build_id}"
          )
          true
        end
      rescue => e
        logger.info "[states-cache] Exception while checking cache freshness: #{e.message}"
        Raven.capture_exception(e)
      end

      def key(id, branch = nil)
        key = "state:#{id}"
        key << "-#{branch}" if branch
        key
      end

      private

      def new_dalli_connection(config)
        servers = config.states_cache.memcached_servers
        options = config.states_cache.memcached_options || {}
        Dalli::Client.new(servers, options.to_h)
      end

      def get(key)
        retry_ring_error do
          pool.with { |client| client.get(key) }
        end
      rescue Dalli::RingError => e
        Metriks.meter("memcached.connect-errors").mark
        raise CacheError, "Couldn't connect to a memcached server: #{e.message}"
      end

      def set(key, data)
        retry_ring_error do
          pool.with { |client| client.set(key, data) }
          logger.info("[states-cache] Setting cache for key=#{key} data=#{data}")
        end
      rescue Dalli::RingError => e
        Metriks.meter("memcached.connect-errors").mark
        logger.info("[states-cache] Writing cache key failed key=#{key} data=#{data}")
        raise CacheError, "Couldn't connect to a memcached server: #{e.message}"
      end

      def retry_ring_error
        retries = 0
        yield
      rescue Dalli::RingError
        retries += 1
        if retries <= 3
          # Sleep for up to 1/2 * (2^retries - 1) seconds
          # For retries <= 3, this means up to 3.5 seconds
          sleep(jitter * (rand(2 ** retries - 1) + 1))
          retry
        else
          raise
        end
      end
    end
  end
end
