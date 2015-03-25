module Travis
  module Hub
    class Worker < Solo
      def setup
        fail ArgumentError, 'missing worker count' unless count
        fail ArgumentError, 'missing worker number' unless number
        super
      end

      def run
        subscribe_to_queue
      end

      def queue
        "builds.#{number}"
      end

      def handle_event(event, payload)
        return super if payload['hub_count'] == count

        # we don't want this, send back to the queue
        Metriks.meter("hub.#{name}.requeue").mark
        publisher = Travis::Amqp::Publisher.jobs('builds')
        publisher.publish(payload, properties: { type: event })
      end
    end
  end
end
