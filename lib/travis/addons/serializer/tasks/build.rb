require 'travis/addons/serializer/formats'

module Travis
  module Addons
    module Serializer
      module Tasks
        class Build
          include Formats

          attr_reader :build, :owner, :repository, :request, :pull_request, :tag, :commit

          def initialize(build)
            @build = build
            @repository = build.repository
            @owner = build.owner
            @request = build.request
            @pull_request = build.pull_request
            @tag = build.tag
            @commit = build.commit
          end

          def data
            {
              repository: repository_data,
              owner: owner ? owner_data : {},
              request: request_data,
              pull_request: pull_request ? pull_request_data : nil,
              tag: tag ? tag_data : nil,
              commit: commit_data,
              build: build_data,
              jobs: build.jobs.map { |job| job_data(job) }
            }
          end

          private

            def build_data
              {
                id: build.id,
                repository_id: build.repository_id,
                commit_id: build.commit_id,
                number: build.number,
                pull_request: build.pull_request?,
                pull_request_number: build.pull_request_number,
                config: build.obfuscated_config.try(:except, :source_key),
                state: build.state.to_s,
                previous_state: build.previous_state,
                started_at: format_date(build.started_at),
                finished_at: format_date(build.finished_at),
                duration: build.duration,
                job_ids: build.jobs.map(&:id),
                type: request.event_type
              }
            end

            def owner_data
              {
                id: owner.id,
                type: owner.class.name,
                login: owner.login
              }
            end

            def repository_data
              {
                id: repository.id,
                github_id: repository.github_id,
                vcs_id: repository.vcs_id,
                vcs_type: repository.vcs_type,
                key: repository.key.try(:public_key),
                slug: repository.slug,
                vcs_slug: repository.vcs_slug,
                name: repository.name,
                owner_name: repository.owner_name,
                owner_email: repository.owner_email,
                owner_avatar_url: repository.owner.try(:avatar_url),
                url: repository.url
              }
            end

            def request_data
              {
                token: request.token,
                head_commit: request.head_commit,
                base_commit: request.base_commit
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

            def pull_request_data
              {
                number: pull_request.number,
                title: pull_request.title,
                head_ref: pull_request.head_ref,
              }
            end

            def tag_data
              {
                name: tag.name
              }
            end

            def stage_data(stage)
              return nil unless stage
              {
                number: stage.number,
                name: stage.name,
                state: stage.state.to_s,
                started_at: format_date(build.started_at),
                finished_at: format_date(build.finished_at),
              }
            end

            def job_data(job)
              {
                id: job.id,
                number: job.number,
                state: job.state.to_s,
                config: job.obfuscated_config.try(:except, :source_key),
                tags: job.tags,
                allow_failure: job.allow_failure,
                started_at: format_date(build.started_at),
                finished_at: format_date(build.finished_at),
                duration: job.duration,
                stage: stage_data(job.stage),
             }
            end
        end
      end
    end
  end
end
