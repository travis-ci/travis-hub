require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/addons/handlers/github_status'

module Travis
  module Addons
    module Handlers
      class GithubCheckStatus < GithubStatus
        include Handlers::Task

        EVENTS = /build:(created|started|finished|canceled|restarted)/

        def handle?
          if github_apps_instllation
            if gh_apps_enabled?
              true
            else
              Addons.logger.error "GitHub Apps installation found, but disabled"
              false
            end
          else
            Addons.logger.error "No GitHub Apps installation found"
            false
          end
        end

        def handle
          run_task(:github_check_status, payload, installation: github_apps_instllation.id)
        end

        def gh_apps_enabled?
          !! repository.managed_by_installation_at
        end

        def github_apps_instllation
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
