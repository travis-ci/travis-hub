require 'metriks'

module Travis
  class Hub
    class Handler
      class Configure < Handler
        def handle
          track_event(:received)
          configure_build
          track_event(:completed)
        rescue StandardError => e
          track_event(:failed)
          raise
        end

        protected

          def configure_build
            debug "Retrieving .travis.yml for payload #{payload.inspect}"
            result = ::Travis::Tasks::ConfigureBuild.new(commit_details).run
            update_job(result)
          end

          def update_job(result)
            debug "Updating Job (id:#{job_id}) with #{result.inspect}"
            job = ::Job.find(job_id)
            job.update_attributes(result)
          end

          def commit_details
            payload[:build]
          end

          def job_id
            payload[:build][:id]
          end

          def track_event(name)
            meter_name = 'travis.hub.configure'
            meter_name = "#{meter_name}.#{name.to_s}"
            Metriks.meter(meter_name).mark
          end
      end
    end
  end
end
