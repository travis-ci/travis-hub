module Travis
  module Hub
    module Database
      class << self
        MSGS = {
          setup: 'Setting up database connection with: %p'
        }

        def connect(config, logger = nil)
          ActiveRecord::Base.establish_connection(config.to_h)
          ActiveRecord::Base.default_timezone = :utc
          ActiveRecord::Base.logger = logger
          logger.info(MSGS[:setup] % except(config.to_h, :adapter, :username, :password)) if logger
        end

        private

          def except(hash, *keys)
            hash.reject { |key, _| keys.include?(key) }
          end
      end
    end
  end
end
