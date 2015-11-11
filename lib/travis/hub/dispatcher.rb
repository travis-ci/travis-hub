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
          ['Organization', 44], # travis-repos
          ['User', 24]          # svenfuchs
        ]
      else
        NEXT = [
          ['Organization', 31], # travis-ci
          ['Organization', 32], # travis-repos
          ['User', 5]           # svenfuchs
        ]
      end

      def next?(job)
        return false unless Travis::Features.enabled_for_all?(:hub_next)
        next_const?(job) || next_rollout?(job)
      end

      def next_const?(job)
        NEXT.include?([job.owner_type, job.owner_id])
      end

      def next_rollout?(job)
        job.owner_id % 100 <= next_percent
      end

      def next_percent
        percent = Travis.redis.get('hub_next_percent') || -1
        percent.to_i
      rescue
        -1
      end
    end
  end
end

