module Travis
  module Hub
    class Dispatcher < Solo
      def setup
        raise ArgumentError, 'missing worker count' unless count
        super
        @publishers = {}
        count.times do |index|
          name = queue_name(index)
          @publishers[name] = Travis::Amqp::Publisher.jobs(name)
        end
      end

      def handle_event(event, payload)
        publisher = @publishers[key_for(payload)]
        publisher.publish(payload, properties: { type: event })
      end

      def key_for(event)
        build_id = ::Job.find(payload.fetch('id')).build_id
        queue_name(build_id % count)
      end

      def queue_name(index)
        "builds.#{index + 1}"
      end
    end
  end
end