require 'travis/hub/helper/context'

module Travis
  module Hub
    module Service
      class UpdateCsvExport
        include Helper::Context

        MSGS = {
          process: 'Processing CSV export for owner_id=%s, report_type=%s',
          forward: 'Forwarding CSV export to billing service',
          complete: 'CSV export request completed successfully',
          error: 'Failed to process CSV export: %s'
        }

        attr_reader :context, :event, :payload

        def initialize(context, event, payload)
          @context = context
          @event = event
          @payload = payload
        end

        def run
          process_csv_export
        end

        private

        def process_csv_export
          owner_id = payload[:owner_id]
          report_type = payload[:report_type]

          logger.info MSGS[:process] % [owner_id, report_type]
          logger.info MSGS[:forward]

          Travis::Sidekiq.billing(
            nil,
            'Travis::Billing::Services::Executions::CsvExport',
            'perform',
            payload
          )

          logger.info MSGS[:complete]
          true
        rescue => e
          logger.error MSGS[:error] % e.message
          Sentry.capture_exception(e) if defined?(Sentry)
          false
        end
      end
    end
  end
end
