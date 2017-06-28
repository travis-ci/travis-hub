require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class GithubStatus < Base
        include Handlers::Task

        EVENTS = /build:(created|started|finished|canceled|restarted)/

        def handle?
          Addons.logger.error "No GitHub OAuth tokens found for #{object.repository.slug}" unless tokens.any?
          tokens.any?
        end

        def handle
          run_task(:github_status, payload, tokens: tokens)
        end

        private

          def tokens
            @tokens ||= users.inject({}) do |tokens, user|
              tokens.merge(user.login => user.github_oauth_token)
            end
          end

          def users
            @users ||= begin
              scope = repository.permissions.where('admin = ? OR push = ?', true, true)
              scope = scope.includes(:user).order('admin DESC')
              users = scope.map(&:user)
              users = [committer] + (users - [committer]) if committer
              users.compact
            end
          end

          def committer
            @committer ||= ::Email.where(email: commit.committer_email).map(&:user).first
          end

          class Instrument < Addons::Instrument
            def notify_completed
              publish
            end
          end
          Instrument.attach_to(self)
      end
    end
  end
end
