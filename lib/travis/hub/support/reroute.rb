module Travis
  # Re-routing messages to another instance:
  #
  # * The global feature flag `hub_next` must be active.
  # * The key `hub_next_owners` can have a set of owner names set (defaults to `OWNERS`).
  # * The key `hub_next_percent` can have a percentage set (compared to the given id).

  class Reroute < Struct.new(:name, :data)
    OWNERS = %w(travis-ci travis-pro travis-repos svenfuchs)

    def run(&block)
      return false unless reroute?
      block.call if block
      true
    end

    def reroute?
      enabled? and by_owner? || rollout?
    end

    private

      def enabled?
        redis.get("feature:#{name}:disabled") == '1'
      end

      def by_owner?
        owners.include?(data[:owner_name])
      end

      def rollout?
        data[:id].to_i % 100 <= percent
      end

      def owners
        @owners ||= begin
          owners = redis.smembers(:"#{name}_owners")
          owners.any? ? owners : OWNERS
        end
      end

      def percent
        percent = redis.get(:"#{name}_percent") || -1
        percent.to_i
      rescue
        -1
      end

      def redis
        Travis::Hub.context.redis # TODO pass in
      end
  end
end
