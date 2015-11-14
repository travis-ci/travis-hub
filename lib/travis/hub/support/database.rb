module Travis
  module Database
    class << self
      def connect(config, logger = nil)
        ActiveRecord::Base.establish_connection(config.to_h)
        ActiveRecord::Base.default_timezone = :utc
        ActiveRecord::Base.logger = logger
      end
    end
  end
end
