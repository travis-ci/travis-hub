require 'travis/hub/app/queue'
require 'travis/hub/services/update_job'

module Travis
  module Hub
    module App
      class Solo < Struct.new(:name)
        def run
          Queue.subscribe(queue, &method(:handle))
        end

        private

          def queue
            QUEUE
          end

          def handle(event, payload)
            Metriks.timer("hub.#{name}.handle").time do
              ActiveRecord::Base.cache do
                handle_event(event, payload)
              end
            end
          end

          def handle_event(event, payload)
            Services::UpdateJob.new(event: event.to_s.split(':').last, data: payload).run
          end
      end
    end
  end
end
