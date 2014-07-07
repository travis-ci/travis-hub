module Travis
  module Hub
    class Worker < Solo
      def setup
        raise ArgumentError, 'missing worker count' unless count
        raise ArgumentError, 'missing worker number' unless number
        super
      end

      def queue
        "builds.#{number}"
      end

      def handle_event(event, payload)
        return super if payload['hub_count'] == count

        # we don't want this, send back to the queue
        publisher = Travis::Amqp::Publisher.jobs('builds')
        publisher.publish(payload, properties: { type: event })
      end

      def enqueue_jobs
        # handled by dispatcher
      end
    end
  end
end