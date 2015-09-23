require 'travis/lock'

module Travis
  module Hub
    module Helper
      module Locking
        def exclusive(key, options = nil, &block)
          options ||= Hub.config.lock
          options[:url] ||= Hub.config.redis.url if options[:strategy] == :redis
          Travis::Lock.exclusive(key, options, &block)
        end
      end
    end
  end
end
