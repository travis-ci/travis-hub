module Travis
  module Hub
    module App
      class Worker < Solo
        attr_accessor :count, :number

        def initialize(name, count, number)
          super(name)
          @count  = count
          @number = number
        end

        private

          def queue
            "#{QUEUE}.#{number}"
          end

          def handle_event(type, payload)
            payload['worker_count'] == count ? super : requeue(type, payload)
          end

          def requeue(type, payload)
            # hub worker count has changed, send this back to the original queue
            Metriks.meter("hub.#{name}.requeue").mark
            publisher = Travis::Amqp::Publisher.jobs('builds')
            publisher.publish(payload, properties: { type: type })
          end

          def missing_argument(name)
            fail ArgumentError, "missing worker #{name}"
          end
      end
    end
  end
end
