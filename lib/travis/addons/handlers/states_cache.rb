require 'travis/support/states_cache'
require 'travis/addons/handlers/generic'

module Travis
  module Addons
    module Handlers
      class StatesCache < Generic
        EVENTS = /build:finished/

        class << self
          attr_reader :states_cache

          def setup
            @states_cache = Travis::StatesCache.new
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
