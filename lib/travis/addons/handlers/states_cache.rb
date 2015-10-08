require 'travis/support/states_cache'
require 'travis/addons/handlers/base'

module Travis
  class StatesCache
    class Memcached
      def update?(id, branch, build_id)
        data = fetch(id, branch)

        if data
          last_id = data['id'].to_i
          stale   = build_id.to_i >= last_id
          Travis.logger.info(
            "[states-cache] cache is #{stale ? 'stale' : 'fresh' }: repo id=#{id} branch=#{branch}, " \
            "last cached build id=#{last_id}, checked build id=#{build_id}"
          )
          stale
        else
          Travis.logger.info(
            "[states-cache] cache does not exist: repo id=#{id} branch=#{branch}, " \
            "checked build id=#{build_id}"
          )
          true
        end
      rescue => e
        puts "[states-cache] Exception while checking cache freshness: #{e.message}", e.backtrace
      end

      def new_dalli_connection
        servers = Travis.config.states_cache.memcached_servers
        options = Travis.config.states_cache.memcached_options || {}
        Dalli::Client.new(servers, options.to_h)
      end
    end
  end
end

module Travis
  module Addons
    module Handlers
      class StatesCache < Base
        EVENTS = 'build:finished'

        class << self
          attr_reader :states_cache

          def setup
            @states_cache ||= Travis::StatesCache.new
          end
        end

        def handle?
          !pull_request?
        end

        def handle
          cache.write(repository_id, branch, 'id' => object.id, 'state' => object.state.try(:to_sym))
        end

        private

          def cache
            self.class.states_cache || fail('States cache not set up.')
          end

          def repository_id
            object.repository_id
          end

          def build_id
            object.source_id
          end

          def branch
            object.commit.branch
          end
      end
    end
  end
end
