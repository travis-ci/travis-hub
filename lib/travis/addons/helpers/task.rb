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

        QUEUE = :'notifications'

        def run_task(*args)
          target = "Travis::Addons::#{self.class.name.split('::').last}::Task"
          args   = deep_clean_strings(args)

          ::Sidekiq::Client.push(
            'queue' => QUEUE,
            'class' => 'Travis::Async::Sidekiq::Worker',
            'args'  => [nil, target, 'perform', *args]
          )
        rescue => e
          Exceptions.handle(Error.new(e, queue, args)) # TODO pass in
        end
      end
    end
  end
end
