require 'travis/hub'

module Travis
  module Hub
    module Sidekiq
      class Worker
        include ::Sidekiq::Worker

        sidekiq_options queue: :hub

        def perform(event, payload)
          event.delete!('"')
          Handler.new(Hub.context, event, JSON.parse(payload)).run
        end
      end
    end
  end
end
