require 'travis/lock'

module Travis
  module Hub
    module Helper
      module Locking
        def exclusive(key, options = nil, &block)
          options ||= config.lock.to_h
          if options[:strategy] == :redis
            options[:url] ||= config.redis.url
            options[:ssl] ||= config[:redis][:ssl]
            options[:ca_path] ||= ENV['REDIS_SSL_CA_PATH'] if ENV['REDIS_SSL_CA_PATH']
            options[:cert] ||= OpenSSL::X509::Certificate.new(File.read(ENV['REDIS_SSL_CERT_FILE'])) if ENV['REDIS_SSL_CERT_FILE']
            options[:key] ||= OpenSSL::PKEY::RSA.new(File.read(ENV['REDIS_SSL_KEY_FILE'])) if ENV['REDIS_SSL_KEY_FILE']
            options[:verify_mode] ||= OpenSSL::SSL::VERIFY_NONE if config[:ssl_verify] == false
          end

          Lock.exclusive(key, options) do
            logger.debug "Locking #{key}"
            block.call
            logger.debug "Releasing #{key}"
          end

        # TODO: move this to travis-locks
        rescue Redis::TimeoutError => e
          count ||= 0
          raise e if count > 10

          count += 1
          error "Redis::TimeoutError while trying to acquire lock for #{key}. Retrying #{count}/10."
          sleep 1
          retry
        end
      end
    end
  end
end
