require 'sidekiq'

module Travis
  module Addons
    module Handlers
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

        def run_task(name, *args)
          Travis::Sidekiq.tasks(name, *deep_clean_strings(args))
        end

        def payload
          @payload ||= Serializer::Tasks::Build.new(object).data
        end

        def config
          @config ||= Config.new(payload, secure_key)
        end

        def secure_key
          repository.key if respond_to?(:repository)
        end
      end
    end
  end
end
