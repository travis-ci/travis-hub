module Travis
  module Hub
    module Database
      class << self
        MSGS = {
          setup: 'Setting up database connection with: %s (%s)',
          count: 'Database connections on %s: size=%s, count=%s, reserved=%s, available=%s, reserved keys=%p'
        }

        SKIP_CONFIG = [:username, :password, :encoding, :min_messages]

        def connect(const, config, logger = nil)
          log_connection_info(const, config, logger) if logger

          const.establish_connection(config.to_h)
          const.default_timezone = :utc
          const.logger = logger

          # start_log_connection_counts(const, logger)
        end

        private

          def start_log_connection_counts(const, logger)
            @thread = Thread.new do
              loop { log_connection_counts(const, logger) }
            end
          end

          def log_connection_info(const, config, logger)
            logger.info(MSGS[:setup] % [except(config.to_h, *SKIP_CONFIG).inspect, const.name])
          end

          def log_connection_counts(const, logger)
            pool      = const.connection_pool
            size      = pool.size
            count     = pool.connections.size
            reserved  = pool.instance_variable_get(:@reserved_connections).size
            keys      = pool.instance_variable_get(:@reserved_connections).keys
            available = pool.instance_variable_get(:@available).instance_variable_get(:@queue).size
            logger.info(MSGS[:count] % [const.name, size, count, reserved, available, keys])
            sleep 60
          rescue Exception => e
            logger.error([e.message].concat(e.backtrace).join("\n"))
          end

          def except(hash, *keys)
            hash.reject { |key, _| keys.include?(key) }
          end
      end
    end
  end
end
