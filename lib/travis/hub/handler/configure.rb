require 'metriks'

module Travis
  class Hub
    class Handler
      class Configure < Handler
        def initialize(event, payload)
          super
          self.payload.job = payload.build unless payload.job?
        end

        def handle
          track_event(:received)
          configure(result)
          track_event(:completed)
        rescue StandardError => e
          track_event(:failed)
          raise
        end

        protected

          def configure(result)
            debug "Updating Job (id:#{payload.job.id}) with #{result.inspect}"
            job = ::Job.find(payload.job.id)
            job.update_attributes(result)
          end

          def result
            debug "Retrieving .travis.yml for payload #{payload.inspect}"
            Task::Request::Configure.new(payload.job).run
          end

          def track_event(name)
            Metriks.meter("travis.hub.configure.#{name}").mark
          end
      end
    end
  end
end
