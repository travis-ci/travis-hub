require 'travis/addons/handlers/base'
require 'travis/addons/support/states_cache'

module Travis
  module Addons
    module Handlers
      class StatesCache < Base
        EVENTS = 'build:finished'

        class << self
          attr_reader :states_cache

          def setup(config, logger)
            @states_cache ||= Travis::StatesCache.new(config, logger)
          end
        end

        def handle?
          !pull_request?
        end

        def handle
          validate_duration
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


          # TODO This logic is here to verify if we ever see builds being
          # finished before they had been started. If so, this should be rolled
          # back. Eventually the worker should send all known timestamps with all
          # state update messages, solving this problem.

          MSGS = {
            missing_duration: 'Missing duration for <%s id=%s> is: %s'
          }

          def validate_duration
            warn_missing_duration if object.duration == 0 || object.duration.nil?
          end

          def warn_missing_duration
            Addons.logger.warn(MSGS[:missing_duration] % [object.class.name, object.id, object.duration.inspect])
          end
      end
    end
  end
end
