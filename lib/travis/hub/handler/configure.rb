require 'metriks'

Travis::Instrumentation.module_eval do
  def track(name)

  end
end
module Travis
  class Hub
    class Handler
      # Handles configure messages which are queued after a Request has
      # been accepted and created.
      class Configure < Handler
        def initialize(event, payload)
          super
          # TODO remove once payloads have a job key
          self.payload.job = self.payload.build unless self.payload.job?
        end

        def handle
          configure(result)
        end
        instrument :handle, :track => true
        new_relic :handle

        protected

          def configure(result)
            job = ::Job.find(payload.job.id)
            job.update_attributes(result)
          end

          def result
            debug "Retrieving .travis.yml for payload #{payload.inspect}"
            Task::Request::Configure.new(payload.job).run
          end
      end
    end
  end
end
