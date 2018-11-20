require 'travis/lock'

module Travis
  module Hub
    module Helper
      module Locking
        def exclusive(key, options = nil, &block)
          options ||= config.lock.to_h
          options[:url] ||= config.redis.url if options[:strategy] == :redis

          Lock.exclusive(key, options) do
            logger.debug "Locking #{key}"
            block.call
            logger.debug "Releasing #{key}"
          end

        # TODO move this to travis-locks
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
