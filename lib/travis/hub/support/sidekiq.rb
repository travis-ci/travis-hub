require 'sidekiq-pro'
require 'travis/exceptions/sidekiq'
require 'travis/metrics/sidekiq'
require 'travis/hub/support/sidekiq/honeycomb'
require 'travis/hub/support/sidekiq/log_format'
require 'travis/hub/support/sidekiq/marginalia'

module Travis
  module Sidekiq

    def redis_ssl_params(config)
      @redis_ssl_params ||= begin
        return nil unless config.redis.ssl

        value = {}
        value[:ca_path] = ENV['REDIS_SSL_CA_PATH'] if ENV['REDIS_SSL_CA_PATH']
        value[:cert] = OpenSSL::X509::Certificate.new(File.read(ENV['REDIS_SSL_CERT_FILE'])) if ENV['REDIS_SSL_CERT_FILE']
        value[:key] = OpenSSL::PKEY::RSA.new(File.read(ENV['REDIS_SSL_KEY_FILE'])) if ENV['REDIS_SSL_KEY_FILE']
        value[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if config.ssl_verify == false
        value
      end
    end

    def setup(config)
      ::Sidekiq.configure_server do |c|
        c.logger.level = Logger::WARN
        c.redis = {
          url: config.redis.url,
          id: nil,
          ssl: config.redis.ssl || false,
          ssl_params: redis_ssl_params(config)
        }

        c.server_middleware do |chain|
          chain.add Travis::Exceptions::Sidekiq if config.sentry && config.sentry.dsn
          chain.add Travis::Metrics::Sidekiq
          chain.add Travis::Hub::Sidekiq::Marginalia, app: 'hub'
          chain.add Travis::Hub::Sidekiq::Honeycomb
        end

        c.logger.formatter = Support::Sidekiq::Logging.new(config.logger || {})

        if pro?
          c.super_fetch!
          c.reliable_scheduler!
        end
      end

      ::Sidekiq.configure_client do |c|
        c.redis = {
          url: config.redis.url,
          id: nil,
          ssl: config.redis.ssl || false,
          ssl_params: redis_ssl_params(config)
        }

        if pro?
          ::Sidekiq::Client.reliable_push!
        end
      end
    end

    def pro?
      ::Sidekiq::NAME == 'Sidekiq Pro'
    end

    extend self
  end
end
