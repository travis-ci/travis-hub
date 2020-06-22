require 'sidekiq/worker'
require 'travis/hub'

module Travis
  module Hub
    module Sidekiq
      class Worker
        include ::Sidekiq::Worker

        sidekiq_options queue: :hub

        # job:test:finish, 518257
        def perform(event, payload)
          Handler.new(Hub.context, event, payload).run
        end
      end
    end
  end
end
