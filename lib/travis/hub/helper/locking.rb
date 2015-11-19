require 'travis/lock'

module Travis
  module Hub
    module Helper
      module Locking
        def exclusive(key, options = nil, &block)
          options ||= config.lock
          options[:url] ||= config.redis.url if options[:strategy] == :redis

          debug "Locking #{key} with: #{options[:strategy]}"
          Lock.exclusive(key, options, &block)
        rescue Redis::TimeoutError => e
          count ||= 0
          raise e if count > 10
          count += 1
          error "Redis::TimeoutError while trying to acquire lock for #{key} (#{options}). Retrying #{count}/10."
          sleep 1
          retry
        end
      end
    end
  end
end
