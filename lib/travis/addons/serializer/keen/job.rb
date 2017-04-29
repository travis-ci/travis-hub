require 'date'

module Travis
  module Addons
    module Serializer
      module Keen
        class Job < Struct.new(:job)
          def data
            {
              jobs: [
                {
                  repository: {
                    id:         repo.id,
                    slug:       repo.slug,
                    private:    repo.private,
                  },
                  owner: {
                    type:       job.owner_type,
                    id:         owner.id,
                    login:      owner.login,
                  },
                  build: {
                    id:         build.id,
                    type:       request.event_type,
                    number:     build.number,
                    branch:     build.branch,
                  },
                  job: {
                    id:         job.id,
                    number:     job.number,
                    state:      job.state,
                    queue:      job.queue,
                    wait_time:  wait_time,
                    queue_time: queue_time,
                    boot_time:  boot_time,
                    run_time:   run_time,
                  }
                }
              ]
            }
          end

          private

            def repo
              job.repository
            end

            def owner
              job.owner
            end

            def request
              build.request
            end

            def build
              job.build
            end

            def wait_time
              return unless job.queued_at && job.created_at
              job.queued_at - job.created_at
            end

            def queue_time
              return unless job.received_at && job.queued_at
              job.received_at - job.queued_at
            end

            def boot_time
              return unless job.started_at && job.received_at
              job.started_at - job.received_at
            end

            def run_time
              return unless job.finished_at && job.started_at
              job.finished_at - job.started_at
            end
        end
      end
    end
  end
end
