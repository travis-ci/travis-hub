require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class GithubStatus < Base
        include Handlers::Task

        EVENTS = /build:(created|started|finished|canceled|restarted)/

        def handle?
          if installation?
            Addons.logger.info "No Commit Status because #{object.repository.slug} is managed by a GitHub Apps installation"
            false
          elsif tokens.empty?
            Addons.logger.error "No Commit Status because no GitHub OAuth tokens found for #{object.repository.slug}"
            false
          else
            true
          end
        end

        def handle
          run_task(:github_status, payload, tokens: tokens, installation: github_apps_installation_id)
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

          def installation?
            !!repository.managed_by_installation_at && !!installation
          end

          def github_apps_installation_id
            !installation.nil? ? installation.github_id : nil
          end

          def installation
            @installation ||= Installation.where(owner: repository.owner, removed_by_id: nil).first
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
