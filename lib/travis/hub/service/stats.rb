require 'keen'
require 'travis/hub/serialize/keen/job'

module Travis
  module Hub
    module Service
      module Stats
        class Push < Struct.new(:context, :params)
          MSGS = {
            pushed: 'Pushed request stats to keen.io',
            failed: 'Failed to push stats to keen.io: %s'
          }

          def run
            publish if publish?
          end

          private

            def publish?
              ENV['KEEN_PROJECT_ID'] || ENV['ENV'] == 'test'
            end

            def publish
              Keen.publish_batch(payload)
              info :pushed
            rescue Keen::HttpError => e
              error :failed, e.message
            end

            def payload
              Serialize::Keen.const_get(type.camelize).new(obj).data
            end

            def obj
              Kernel.const_get(type.camelize).find(id)
            end

            def type
              params[:type]
            end

            def type
              params[:id]
            end
        end
      end
    end
  end
end
