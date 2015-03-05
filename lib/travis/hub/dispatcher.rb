module Travis
  module Hub
    class Dispatcher < Solo
      def setup
        fail ArgumentError, 'missing worker count' unless count
        super
        @publishers = {}
        count.times do |index|
          name = queue_name(index)
          Travis.logger.info('[hub] creating publisher %p' % name)
          @publishers[name] = Travis::Amqp::Publisher.jobs(name)
          Travis.logger.info('[hub] publisher created')
        end
      end

      def handle_event(event, payload)
        key       = key_for(payload)
        publisher = @publishers[key]
        Metriks.meter("hub.#{name}.delegate.#{key}").mark
        publisher.publish(payload.merge('hub_count' => count), properties: { type: event })
      end

      def key_for(payload)
        source_id = ::Job.find(payload.fetch('id')).source_id
        queue_name(source_id % count)
      end

      def queue_name(index)
        "builds.#{index + 1}"
      end

      def enqueue_jobs
        # handled by enqueue
      end
    end
  end
end
