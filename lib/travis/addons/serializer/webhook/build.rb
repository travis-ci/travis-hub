require 'travis/addons/serializer/formats'
require 'travis/addons/serializer/webhook/build/message'

module Travis
  module Addons
    module Serializer
      module Webhook
        class Build
          include Formats

          attr_reader :build, :commit, :request, :repository

          def initialize(build)
            @build = build
            @commit = build.commit
            @request = build.request
            @repository = build.repository
          end

          def data
            data = {
              id: build.id,
              repository: repository_data,
              number: build.number,
              config: build.obfuscated_config,
              status: result(build.state),
              result: result(build.state),
              status_message: build_result_message,
              result_message: build_result_message,
              started_at: format_date(build.started_at),
              finished_at: format_date(build.finished_at),
              duration: build.duration,
              build_url: build_url,
              commit_id: commit.id,
              commit: commit.commit,
              base_commit: request.base_commit,
              head_commit: request.head_commit,
              branch: commit.branch,
              message: commit.message,
              compare_url: commit.compare_url,
              committed_at: format_date(commit.committed_at),
              author_name: commit.author_name,
              author_email: commit.author_email,
              committer_name: commit.committer_name,
              committer_email: commit.committer_email,
              matrix: build.jobs.map { |job| job_data(job) },
              type: build.event_type,
              state: build.state.to_s,
              pull_request: build.pull_request?,
              pull_request_number: build.pull_request_number,
              pull_request_title: build.pull_request_title,
              tag: commit.tag_name
            }

            if commit.pull_request?
              # TODO not sure why we'd overwrite this at all. should be populated on the build, no?
              data['pull_request_number'] ||= commit.pull_request_number
            end

            data
          end

          def repository_data
            {
              id: repository.id,
              name: repository.name,
              owner_name: repository.owner_name,
              url: repository.url
            }
          end

          def job_data(job)
            {
              id: job.id,
              repository_id: job.repository_id,
              parent_id: job.source_id,
              number: job.number,
              state: job.finished? ? 'finished' : job.state.to_s,
              config: job.obfuscated_config,
              status: result(job.state),
              result: result(job.state),
              commit: commit.commit,
              branch: commit.branch,
              message: commit.message,
              compare_url: commit.compare_url,
              started_at: format_date(job.started_at),
              finished_at: format_date(job.finished_at),
              committed_at: format_date(commit.committed_at),
              author_name: commit.author_name,
              author_email: commit.author_email,
              committer_name: commit.committer_name,
              committer_email: commit.committer_email,
              allow_failure: job.allow_failure
            }
          end

          def result(state)
            case state.try(:to_sym)
            when :passed then 0
            when :failed, :errored then 1
            else nil
            end
          end

          def build_result_message
            Message.new(build).short
          end

          def build_url
            ["https://#{Travis.config.host}", repository.slug, 'builds', build.id].join('/')
          end
        end
      end
    end
  end
end
