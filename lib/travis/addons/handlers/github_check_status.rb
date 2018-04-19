require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/addons/handlers/github_status'

module Travis
  module Addons
    module Handlers
      class GithubCheckStatus < GithubStatus
        include Handlers::Task

        def handle?
          if gh_apps_enabled?
            installation = Installation.where(owner: repository.owner, removed_by_id: nil).first
            if installation
              payload.merge!({installation: installation.id})
              true
            elsif tokens.any?
              Addons.logger.error "Falling back to user tokens"
              true
            else
              false
            end
          else
            Addons.logger.error "No GitHub OAuth tokens found for #{object.repository.slug}" unless tokens.any?
            tokens.any?
          end
        end

        def gh_apps_enabled?
          !! repository.managed_by_installation_at
        end
      end
    end
  end
end
