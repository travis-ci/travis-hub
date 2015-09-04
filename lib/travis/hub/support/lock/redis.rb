begin
  require 'redlock'
rescue LoadError
end

module Travis
  module Hub
    module Support
      module Lock
        class Redis < Struct.new(:name, :options)
          TTL = 5 * 60

          def exclusive
            locks.lock(key, TTL) do |lock|
              if lock
                yield
              else
                raise "Could not obtain lock for #{key.inspect} on Redis (#{locks.inspect})."
              end
            end
          end

          private

            def locks
              @locks ||= Redlock::Client.new([Travis::Scheduler.config.redis.url])
            end

            def key
              name
            end
        end
      end
    end
  end
end
