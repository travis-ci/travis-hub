require 'keen'
require 'travis/addons/handlers/base'
require 'travis/addons/serializer/keen/job'

module Travis
  module Addons
    module Handlers
      class Keenio < Base
        EVENTS = 'job:finished'

        MSGS = {
          failed: 'Failed to push stats to keen.io: %s'
        }

        def handle?
          ENV['KEEN_PROJECT_ID']
        end

        def handle
          publish
        end

        private

          def publish
            ::Keen.publish_batch(data)
          rescue ::Keen::HttpError => e
            logger.error MSGS[:failed] % e.message
          end

          def data
            @data ||= Serializer::Keen::Job.new(object).data
          end

          def logger
            Addons.logger
          end

          class EventHandler < Addons::Instrument
            def notify_completed
              publish
            end
          end
          EventHandler.attach_to(self)
      end
    end
  end
end
