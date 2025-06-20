require 'travis/hub/helper/context'

module Travis
  module Hub
    module Service
      class UpdateCsv_export < Struct.new(:data)
        include Helper::Context

        MSGS = {
          process: 'Processing CSV export for owner_id=%s, report_type=%s',
          forward: 'Forwarding CSV export to billing service',
          complete: 'CSV export request completed successfully',
          error: 'Failed to process CSV export: %s'
        }

        def run
          process_csv_export
        end

        private

        def process_csv_export
          owner_id = data['owner_id']
          report_type = data['report_type']

          logger.info MSGS[:process] % [owner_id, report_type]
          logger.info MSGS[:forward]

          Travis::Sidekiq.billing(
            nil,
            'Travis::Billing::Services::Executions::CsvExport',
            'perform',
            data
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
