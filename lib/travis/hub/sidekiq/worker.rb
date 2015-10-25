require 'sidekiq/worker'
require 'travis/hub/app/handler'

module Travis
  module Hub
    module Sidekiq
      class Worker
        include ::Sidekiq::Worker

        sidekiq_options queue: :hub

        def perform(event, payload)
          App::Handler.new(event, payload).run
        end
      end
    end
  end
end
