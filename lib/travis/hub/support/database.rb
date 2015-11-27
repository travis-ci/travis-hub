module Travis
  module Database
    class << self
      MSGS = {
        setup: 'Setting up database connection with: %s (%s)',
        count: 'Database connections on %s: size=%s, count=%s, reserved=%s, available=%s, reserved keys=%p'
      }

      def connect(const, config, logger = nil)
        @connected ||= {}
        return if @connected[const]
        establish_connection(const, config, logger)
        @connected[const] = true
      end

      private

        def establish_connection(const, config, logger)
          log_connection_info(const, config, logger) if logger
          const.default_timezone = :utc
          const.establish_connection(config.to_h)
          # const.logger = logger
        end

        def log_connection_info(const, config, logger)
          skip = [:adapter, :host, :port, :username, :password, :encoding, :min_messages]
          logger.info(MSGS[:setup] % [except(config.to_h, *skip).inspect, const.name])
        end

        def start_log_connection_counts(const, logger)
          @thread = Thread.new do
            loop { log_connection_counts(const, logger) }
          end
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
