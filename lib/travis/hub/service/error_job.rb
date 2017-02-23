require 'travis/hub/helper/context'
require 'travis/hub/model/job'
require 'travis/hub/support/logs'

module Travis
  module Hub
    module Service
      class ErrorJob < Struct.new(:data)
        include Helper::Context

        MSGS = {
          error:          'Erroring <Job id=%s>. Reason: %s',
          resets_limited: 'Resets limited: %{resets}'
        }

        LOGS = {
          resets_limited: 'Automatic restarts limited: Please try restarting this job later or contact support@travis-ci.com.',
        }

        def run
          logger.error MSGS[:error] % [job.id, reason]
          error
          update_log
        end

        private

          def error
            job.finish!(state: :errored)
          end

          def update_log
            logs.update(id, LOGS[:resets_limited])
          end

          def job
            @job ||= Job.find(id)
          end

          def id
            data[:id]
          end

          def reason
            msg = MSGS[data[:reason]] || raise('No reason given.')
            msg % data
          end

          def logs
            Travis::Hub::Support::Logs.new(config[:logs_api])
          end
      end
    end
  end
end
