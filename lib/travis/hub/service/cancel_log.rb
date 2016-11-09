require 'travis/hub/helper/context'
require 'travis/hub/model/job'
require 'travis/hub/support/logs'

module Travis
  module Hub
    module Service
      class CancelLog < Struct.new(:data)
        include Helper::Context

        LOGS = {
          canceled:     'This job was cancelled because the "Auto Cancellation" feature is currently enabled, and a more recent build (#%{number}) for %{info} came in while this job was waiting to be processed.',
          push:         'branch %{branch}',
          pull_request: 'pull request #%{pull_request_number}',
        }

        def run
          logs.put(id, msg)
        end

        private

          def msg
            LOGS[:canceled] % data.merge(info: LOGS[event] % data)
          end

          def id
            data[:id]
          end

          def event
            data[:event].to_sym
          end

          def data
            @data ||= super.map { |key, value| [key.to_sym, value] }.to_h
          end

          def logs
            Logs.new(config[:logs], context.logger)
          end
      end
    end
  end
end
