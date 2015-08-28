module Travis
  module Hub
    class Worker < Solo
      attr_accessor :count, :number

      def initialize(name, count, number)
        super(name)
        @count  = count.to_i
        @number = number.to_i
      end

      private

        def queue
          "#{QUEUE}.#{number}"
        end

        def handle_event(event, payload)
          payload['worker_count'] == count ? super : requeue(event, payload)
        end

        def requeue(event, payload)
          # hub worker count has changed, send this back to the original queue
          Metriks.meter("hub.#{name}.requeue").mark
          publisher = Travis::Amqp::Publisher.jobs('builds')
          publisher.publish(payload, properties: { type: event })
        end

        def missing_argument(name)
          fail ArgumentError, "missing worker #{name}"
        end
    end
  end
end
