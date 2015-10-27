require 'travis/amqp'

module Travis
  module Hub
    module Amqp
      class << self
        def setup(config)
          amqp = Travis::Amqp.setup(config)
          declare_exchanges_and_queues(amqp)
          amqp
        end

        private

          def declare_exchanges_and_queues(amqp)
            channel = amqp.connection.create_channel
            channel.exchange('reporting', durable: true, auto_delete: false, type: :topic)
            channel.queue('builds.linux', durable: true, exclusive: false)
          end
      end
    end
  end
end
