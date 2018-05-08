require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/addons/handlers/github_status'
require 'travis/rollout'

module Travis
  module Addons
    module Handlers
      class GithubCheckStatus < GithubStatus
        include Handlers::Task

        EVENTS = /build:(created|started|finished|canceled|restarted)/

        def handle?
          installation?
        end

        def handle
          run_task(:github_check_status, payload, installation: installation.github_id)
        end

        def installation?
          !!repository.managed_by_installation_at && !!installation
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
