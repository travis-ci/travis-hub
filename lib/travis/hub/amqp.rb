module Travis
  module Hub
    module Amqp
      autoload :HotBunnies, 'travis/hub/processing/hot_bunnies'
      autoload :Amqp,       'travis/hub/processing/amqp'

      class << self
        def subscribe(options, &block)
          adapter.subscribe(options, &block)
        end

        def publish(queue, options, &block)
          adapter.publish(queue, options, &block)
        end

        protected

          def adapter
            @adapter ||= RUBY_PLATFORM == 'java' ? HotBunnies.new : Amqp.new
          end
      end
    end
  end
end
