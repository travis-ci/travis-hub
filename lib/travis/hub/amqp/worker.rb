module Travis
  module Hub
    class Amqp
      class Worker < Solo
        attr_accessor :number

        def initialize(context, name, options)
          super
          @number = options[:number] || 1
        end

        private

          def queue
            "#{super}.#{number}"
          end

          def handle(event, payload)
            payload.delete('worker_count') == count ? super : requeue(event, payload)
          end

          def requeue(event, payload)
            # hub worker count has changed, send this back to the original queue
            context.amqp.publish('builds', event, payload)
            meter("hub.#{name}.requeue")
          end

          def missing_argument(name)
            fail ArgumentError, "missing worker #{name}"
          end
      end
    end
  end
end
