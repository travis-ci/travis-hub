require 'travis/addons/serializer/formats'

module Travis
  module Addons
    module Serializer
      module Pusher
        class Job
          include Formats

          attr_reader :job, :options

          def initialize(job, options = {})
            @job = job
            @options = options
          end

          def data
            job_data.merge(
              commit: commit_data,
              stage:  job.stage ? stage_data : nil
            )
          end

          private

            def job_data
              {
                id: job.id,
                repository_id: job.repository_id,
                repository_slug: job.repository.slug,
                repository_private: job.repository.private,
                build_id: job.source_id,
                commit_id: job.commit_id,
                number: job.number,
                state: job.state.to_s,
                started_at: format_date(job.started_at),
                finished_at: format_date(job.finished_at),
                queue: job.queue,
                allow_failure: job.allow_failure,
                updated_at: format_date_with_ms(job.updated_at)
              }
            end

            def commit_data
              {
                id: commit.id,
                sha: commit.commit,
                branch: commit.branch,
                message: commit.message,
                committed_at: format_date(commit.committed_at),
                author_name: commit.author_name,
                author_email: commit.author_email,
                committer_name: commit.committer_name,
                committer_email: commit.committer_email,
                compare_url: commit.compare_url,
              }
            end

            def stage_data
              {
                id: stage.id,
                build_id: stage.build.id,
                number: stage.number,
                name: stage.name,
                state: stage.state,
                started_at: format_date(stage.started_at),
                finished_at: format_date(stage.finished_at),
              }
            end

            def commit
              job.commit
            end

            def stage
              job.stage
            end
        end
      end
    end
  end
end
