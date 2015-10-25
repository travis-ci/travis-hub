require 'travis/hub/app/drain'
require 'travis/hub/app/queue'
require 'travis/hub/app/solo'
require 'travis/hub/support/reroute'

module Travis
  module Hub
    class App
      class Dispatcher < Solo
        attr_reader :publishers

        def initialize(*)
          super
          @publishers = {}
        end

        private

          def handle(type, payload)
            with_active_record do
              job = ::Job.find(payload.fetch('id'))
              key = reroute?(job) ? :next : job.source_id % count + 1
              puts "Routing #{type} for <Job id=#{job.id}> to #{queue_for(key)}."
              publish(key, type, payload)
            end
          end

          def handle(type, payload)
            job = ::Job.find(payload.fetch('id'))
            handler = next?(job) ? :drain : :dispatch
            send(job, type, payload)
          end

          def drain(job, type, payload)
            Drain.new.handle(type, payload)
          end

          def dispatch(job, type, payload)
            id  = job.source_id
            key = queue_for(id % count + 1)
            # puts "Routing #{type} for <Job id=#{payload.fetch('id')}> to #{key}."
            publishers[key].publish(payload.merge(worker_count: count), properties: { type: type })
            meter(key)
          end

          def publish(key, type, payload)
            publisher = publisher(queue_for(key))
            publisher.publish(payload.merge(worker_count: count), properties: { type: type })
            meter("hub.#{name}.delegate.#{key}")
          end

          def reroute?(job)
            Reroute.new(:hub_next, id: job.id, owner_name: job.repository.owner_name).run
          end

          def publisher(name)
            publishers[name] ||= Travis::Amqp::Publisher.jobs(name)
          end

          def queue_for(num)
            "#{queue}.#{num}"
          end

          def with_active_record(&block)
            ActiveRecord::Base.connection_pool.with_connection(&block)
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
end
