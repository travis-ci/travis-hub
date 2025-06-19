require 'travis/addons/handlers/base'

module Travis
  module Addons
    module Handlers
      class CsvExport < Base
        EVENTS = ['csv_export:create'].freeze
        KEY = :csv_export

        MSGS = {
          processing: 'Processing CSV export request for owner_id=%s',
          failed: 'Failed to process CSV export: %s'
        }

        def handle?
          true
        end

        def handle
          process_csv_export
        end

        private

        def process_csv_export
          owner_id = payload['owner_id']
          logger.info MSGS[:processing] % owner_id

          Travis::Sidekiq.billing(
            nil,
            'Travis::Billing::Services::Executions::CsvExport',
            'perform',
            payload
          )
        rescue StandardError => e
          logger.error MSGS[:failed] % e.message
        end

        def logger
          Addons.logger
        end

        # EventHandler for instrumentation
        class EventHandler < Addons::Instrument
          def notify_completed
            publish(
              owner_id: handler.payload['owner_id'],
              report_type: handler.payload['report_type']
            )
          end
        end
        EventHandler.attach_to(self)
      end
    end
  end
end
