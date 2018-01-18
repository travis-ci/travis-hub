require 'travis/hub/helper/context'
require 'travis/hub/helper/string'

module Travis
  module Hub
    # Re-routing messages to another instance:
    #
    # * The global feature flag `hub_next` must be active.
    # * The key `hub_next_owners` can have a set of owner names set (defaults to `OWNERS`).
    # * The key `hub_next_percent` can have a percentage set (compared to the given id).

    class Reroute < Struct.new(:type, :event, :payload)
      class Amqp
        def publish(context, queue, event, payload)
          context.amqp.publish(queue, event, payload)
        end
      end

      class Sidekiq
        def publish(context, queue, event, payload)
          ::Sidekiq::Client.push(
            'queue' => queue,
            'class' => 'Travis::Hub::Sidekiq::Worker',
            'args'  => [event, payload]
          )
        end
      end

      include Helper::Context, Helper::String

      OWNERS = %w(travis-ci travis-pro travis-repos svenfuchs)
      QUEUES = { amqp: 'builds.next', sidekiq: 'hub' }

      def run
        reroute || true if reroute?
      end

      def reroute?
        dyno? and enabled? and (by_owner? or by_percent?)
      end

      def reroute
        target = ENV['REROUTE_TARGET'] || :amqp # context.redis.get("#{name}_target")
        queue  = QUEUES[target.to_sym]
        info "Routing #{type}:#{event} for id=#{object.id} to #{target}=#{queue}"
        publisher = self.class.const_get(camelize(target)).new
        publisher.publish(context, queue, [type, event].join(':'), payload)
      end

      private

        def dyno?
          ENV['REROUTE'] && ENV['DYNO'].to_s.include?(ENV['REROUTE'])
        end

        def enabled?
          context.redis.get("feature:#{name}:disabled") == '1'
        end

        def by_owner?
          owners.include?(object.repository.owner_name)
        end

        def by_percent?
          object.id.to_i % 100 < percent
        end

        def owners
          @owners ||= begin
            owners = context.redis.smembers(:"#{name}_owners")
            owners.any? ? owners : OWNERS
          end
        end

        def percent
          percent = ENV['REROUTE_PERCENT'] || context.redis.get(:"#{name}_percent") || -1
          Metriks.gauge('hub.reroute.percent').set(percent.to_i)
        rescue => e
          Raven.capture_exception(e)
          percent ? percent.to_i : -1
        end

        def object
          @object ||= Kernel.const_get(camelize(type)).find(payload.fetch(:id))
        end

        def name
          "#{config.name}_next"
        end
    end
  end
end
