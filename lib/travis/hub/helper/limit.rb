module Travis
  module Hub
    class Limit < Struct.new(:redis, :name, :id, :opts)
      def limited?
        count >= max && started && now >= started + after
      end

      def record(time = Time.now)
        add(time)
        start(time) unless started
      end

      def to_s
        "#{count} #{name} between #{started.to_s} and #{now.to_s} (max: #{max}, after: #{after})"
      end

      private

        def now
          Time.now
        end

        def count
          redis.llen(key(:all))
        end

        def add(time)
          redis.lpush(key(:all), time || Time.now)
          redis.expire(key(:all), 24 * 60 * 60)
        end

        def start(time)
          redis.set(key(:started), time || Time.now, ex: 24 * 60 * 60)
        end

        def started
          started = redis.get(key(:started))
          Time.parse(started) if started
        end

        def key(key)
          [:hub, :limit, name, id, key].join(':')
        end

        def max
          opts[:max]
        end

        def after
          opts[:after]
        end
    end
  end
end
