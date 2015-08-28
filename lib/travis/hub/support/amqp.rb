require 'travis/support/amqp'

module Travis
  module Hub
    module Support
      module Amqp
        class << self
          def setup(config)
            Travis::Amqp.config = config
            declare_exchanges_and_queues
          end

          private

            def declare_exchanges_and_queues
              channel = Travis::Amqp.connection.create_channel
              channel.exchange('reporting', durable: true, auto_delete: false, type: :topic)
              channel.queue('builds.linux', durable: true, exclusive: false)
            end
        end
      end
    end
  end
end
