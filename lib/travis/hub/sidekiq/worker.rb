require 'monitor'
require 'sidekiq/worker'
require 'travis/hub'

module Travis
  module Hub
    module Sidekiq
      class Worker
        @monitor = Monitor.new

        def self.context
          @monitor.synchronize { @context ||= Context.new }
        end

        include ::Sidekiq::Worker

        sidekiq_options queue: :hub

        def perform(event, payload)
          App::Handler.new(event, payload).run
        end
      end
    end
  end
end
