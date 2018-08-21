require 'travis/addons/serializer/formats'
require 'travis/hub/model/branch'

module Travis
  module Addons
    module Serializer
      module Pusher
        class Build
          include Formats

          attr_reader :build, :options

          def initialize(build, options = {})
            @build = build
            @options = options
          end

          def data
            {
              repository: repository_data,
              commit: commit_data,
              build: build_data,
              stages: build.stages.map { |stage| stage_data(stage) }
            }
          end

          private

            def repository_data
              {
                id: repository.id,
                slug: repository.slug,
                description: repository.description,
                private: repository.private,
                last_build_id: repository.last_build_id,
                last_build_number: repository.last_build_number,
                last_build_state: repository.last_build_state.to_s,
                last_build_duration: repository.last_build_duration,
                last_build_language: nil,
                last_build_started_at: format_date(repository.last_build_started_at),
                last_build_finished_at: format_date(repository.last_build_finished_at),
                github_language: repository.github_language,
                default_branch: {
                  name: repository.default_branch,
                  last_build_id: last_build_on_default_branch_id(repository)
                },
                active: repository.active,
                current_build_id: repository.current_build_id
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

            def stage_data(stage)
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

            def build_data
              {
                id: build.id,
                repository_id: build.repository_id,
                commit_id: build.commit_id,
                number: build.number,
                pull_request: build.pull_request?,
                pull_request_title: build.pull_request_title,
                pull_request_number: build.pull_request_number,
                state: build.state.to_s,
                started_at: format_date(build.started_at),
                finished_at: format_date(build.finished_at),
                duration: build.duration,
                job_ids: build.job_ids,
                event_type: build.event_type,
                updated_at: format_date_with_ms(build.updated_at),

                # this is a legacy thing, we should think about removing it
                commit: commit.commit,
                branch: commit.branch,
                message: commit.message,
                compare_url: commit.compare_url,
                committed_at: format_date(commit.committed_at),
                author_name: commit.author_name,
                author_email: commit.author_email,
                committer_name: commit.committer_name,
                committer_email: commit.committer_email,

                created_by: created_by
              }
            end

            def repository
              build.repository
            end

            def commit
              build.commit
            end

            def stages
              build.stages
            end

            def created_by
              return unless sender = build.sender

              {
                id: sender.id,
                name: sender.name,
                login: sender.login,
                avatar_url: sender.avatar_url
              }
            end

            def last_build_on_default_branch_id(repository)
              default_branch = Branch.where(repository_id: repository.id, name: repository.default_branch).order('name ASC').first

              if default_branch
                default_branch.last_build_id
              end
            end

        end
      end
    end
  end
end
