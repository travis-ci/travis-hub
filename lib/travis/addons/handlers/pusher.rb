require 'travis/addons/handlers/base'
require 'travis/addons/serializer/pusher/build'
require 'travis/addons/serializer/pusher/job'
require 'travis/sidekiq'
require 'travis/rollout'

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
          params = { event: event }
          uid = "#{object.repository.owner_id}-#{object.repository.owner_type[0]}"
          Travis::Rollout.run('user-channel', redis: Travis::Hub.context.redis, uid: uid) do
            params[:user_ids] = user_ids
          end

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
