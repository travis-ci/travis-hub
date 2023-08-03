require 'travis/hub'

module Travis
  module Hub
    module Sidekiq
      class Worker
        include ::Sidekiq::Worker

        sidekiq_options queue: :hub

        def perform(event, payload)
          event.delete!('"')
          payload = JSON.parse(payload) is payload.is_a?(String)
          Handler.new(Hub.context, event, payload).run
        end
      end
    end
  end
end
