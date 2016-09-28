require 'sidekiq'
require 'travis/addons/helpers/coder'

module Travis
  module Addons
    module Helpers
      module Task
        class Error < StandardError
          extend Forwardable

          def_delegators :exception, :message, :backtrace, :class

          attr_reader :exception, :queue, :args, :options

          def initialize(exception, queue, args, options = {})
            @exception = exception
            @queue = queue
            @args = args
            @options = options
          end

          def data
            { queue: queue, args: args }
          end

          def tags
            { app: :hub, context: :run_task }.merge(options[:tags] || {})
          end
        end

        include Coder

        def run_task(queue, *args)
          name = self.class.name.split('::').last
          args = deep_clean_strings(args)
          Travis::Sidekiq.tasks(queue, name, *args)
        rescue => e
          Exceptions.handle(Error.new(e, queue, args)) # TODO pass in
        end
      end
    end
  end
end
