module Travis
  module Hub
    module Database
      class << self
        MSGS = {
          setup: 'Setting up database connection with: %s',
          count: 'Database connection count: %s'
        }

        SKIP_CONFIG = [:username, :password, :encoding, :min_messages]

        def connect(config, logger = nil)
          log_connection_info(config, logger) if logger

          ActiveRecord::Base.establish_connection(config.to_h)
          ActiveRecord::Base.default_timezone = :utc
          ActiveRecord::Base.logger = logger

          Thread.new { loop { log_connection_count(logger) } }
        end

        private

          def log_connection_info(config, logger)
            logger.info(MSGS[:setup] % except(config.to_h, *SKIP_CONFIG).inspect)
          end

          def log_connection_count(logger)
            sleep 60
            logger.info(MSGS[:count] % connection_count)
          rescue Exception => e
            logger.error([e.message].concat(e.backtrace).join("\n"))
          end

          def connection_count
            ActiveRecord::Base.connection_pool.connections.size
          end

          def except(hash, *keys)
            hash.reject { |key, _| keys.include?(key) }
          end
      end
    end
  end
end
