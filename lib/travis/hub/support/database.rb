module Travis
  module Hub
    module Database
      class << self
        MSGS = {
          setup: 'Setting up database connection with: %s',
          count: 'Database connection count: %s'
        }

        def connect(config, logger = nil)
          ActiveRecord::Base.establish_connection(config.to_h)
          ActiveRecord::Base.default_timezone = :utc
          ActiveRecord::Base.logger = logger
          logger.info(MSGS[:setup] % except(config.to_h, :adapter, :username, :password).inspect) if logger
          # Thread.new { loop { log_connection_count(logger) } }
        end

        private

          def except(hash, *keys)
            hash.reject { |key, _| keys.include?(key) }
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
      end
    end
  end
end
