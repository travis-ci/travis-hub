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
        end
      end
    end
  end
end
