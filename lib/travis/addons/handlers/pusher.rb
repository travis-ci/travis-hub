require 'travis/addons/handlers/base'
require 'travis/addons/serializer/pusher/build'
require 'travis/addons/serializer/pusher/job'
require 'travis/sidekiq'

module Travis
  module Addons
    module Handlers
      class Pusher < Base
        EVENTS = [
          /^build:(created|started|finished|canceled|restarted)/,
          /^job:(created|received|started|finished|canceled|restarted)/
        ]
        QUEUE = :'pusher-live'

        attr_reader :channels

        def handle?
          true
        end

        def handle
          # we need to always make sure that the data is fresh, because Active
          # Record doesn't always refresh the updated_at column
          object.reload

          params = { event: event, user_ids: user_ids }
          Travis::Sidekiq.live(deep_clean_strings(payload), params)
        end

        def data
          @data ||= Serializer::Pusher.const_get(object_type.camelize).new(object).data
        end

        def payload
          Serializer::Pusher.const_get(object_type.camelize).new(object, params: data).data
        end

        def user_ids
          object.repository.permissions.pluck(:user_id)
        end

        class Instrument < Addons::Instrument
          def notify_completed
            publish
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end
