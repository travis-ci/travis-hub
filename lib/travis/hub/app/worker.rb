module Travis
  module Hub
    class App
      class Worker < Solo
        attr_accessor :number

        def initialize(context, name, options)
          super
          @number = options[:number] || 1
        end

        def run
          subscribe
        end

        private

          def queue
            "#{super}.#{number}"
          end

          def handle(type, payload)
            payload.delete('worker_count') == count ? super : requeue(type, payload)
          end

          def requeue(type, payload)
            # hub worker count has changed, send this back to the original queue
            # TODO use context.amqp
            publisher = Travis::Amqp::Publisher.jobs('builds')
            publisher.publish(payload, properties: { type: type })
            meter("hub.#{name}.requeue")
          end

          def missing_argument(name)
            fail ArgumentError, "missing worker #{name}"
          end
      end
    end
  end
end
