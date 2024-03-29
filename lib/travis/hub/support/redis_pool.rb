require 'connection_pool'
require 'redis'
require 'metriks'

module Travis
  class RedisPool
    attr_reader :pool

    def initialize(options = {})
      pool_options = options.delete(:pool) || {}
      @pool = ConnectionPool.new(pool_options) do
        ::Redis.new(options)
      end
    end

    def method_missing(name, *args, &block)
      # TODO: for some reason this blocks during tests
      # timer = Metriks.timer('redis.pool.wait').time
      pool.with do |redis|
        # timer.stop
        if redis.respond_to?(name)
          # Metriks.timer("redis.operations").time do
          redis.send(name, *args, &block)
          # end
        else
          super
        end
      end
    end
  end
end
