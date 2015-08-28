require 'travis/addons/serializer/formats'

module Travis
  module Addons
    module Serializer
      module Generic
        class Job
          include Formats

          attr_reader :job

          def initialize(job)
            @job = job
          end

          def data
            {
              'job' => job_data,
            }
          end

          private

            def job_data
              {
                'queue' => job.queue,
                'created_at' => job.created_at,
                'started_at' => job.started_at,
                'finished_at' => job.finished_at,
              }
            end
        end
      end
    end
  end
end
