module Travis
  module Hub
    class Dispatcher < Solo
      def setup
        fail ArgumentError, 'missing worker count' unless count
        super

        @publishers = {}

        count.times do |index|
          name = queue_name(index + 1)
          @publishers[name] = Travis::Amqp::Publisher.jobs(name)
        end

        name = queue_name(:next)
        @publishers[name] = Travis::Amqp::Publisher.jobs(name)
      end

      def run
        subscribe_to_queue
      end

      def handle_event(event, payload)
        key       = key_for(payload)
        publisher = @publishers[key]
        Metriks.meter("hub.#{name}.delegate.#{key}").mark
        # puts "Routing #{event} for <Job id=#{payload.fetch('id')}> to #{key}."
        publisher.publish(payload.merge('hub_count' => count), properties: { type: event })
      end

      def key_for(payload)
        job = ::Job.find(payload.fetch('id'))
        key = next?(job) ? :next : job.source_id % count + 1
        queue_name(key)
      end

      def queue_name(key)
        "builds.#{key}"
      end

      if ENV['ENV'] == 'staging'
        NEXT = [
          ['Organization', 287], # travis-repos
          ['User', 3664]         # svenfuchs
        ]
      else
        NEXT = [
          ['Organization', 87],  # travis-ci
          ['Organization', 340], # travis-repos
          ['User', 8]            # svenfuchs
        ]
      end

      def next?(job)
        Travis::Features.enabled_for_all?(:hub_next) && NEXT.include?([job.owner_type, job.owner_id])
      end
    end
  end
end

