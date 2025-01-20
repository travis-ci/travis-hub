require 'connection_pool'
require 'redis'
require 'metriks'

module Travis
  class RedisPool
    attr_reader :pool

    def initialize(options = {})
      config = options.redis.to_h
      pool_options = config.delete(:pool) || {}
      cfg = config.to_h
      cfg = cfg.merge(ssl_params: redis_ssl_params(options)) if cfg[:ssl]
      @pool = ConnectionPool.new(pool_options) do
        ::Redis.new(cfg)
      end
    end

    def redis_ssl_params(config)
      @redis_ssl_params ||= begin
        return nil unless config[:redis][:ssl]

        value = {}
        value[:ca_path] = ENV['REDIS_SSL_CA_PATH'] if ENV['REDIS_SSL_CA_PATH']
        value[:cert] = OpenSSL::X509::Certificate.new(File.read(ENV['REDIS_SSL_CERT_FILE'])) if ENV['REDIS_SSL_CERT_FILE']
        value[:key] = OpenSSL::PKEY::RSA.new(File.read(ENV['REDIS_SSL_KEY_FILE'])) if ENV['REDIS_SSL_KEY_FILE']
        value[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if config[:ssl_verify] == false
        value
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
