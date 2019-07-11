require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/merge'

module Travis
  module Addons
    module Handlers
      class Merge < Base
        EVENTS = /(build|job):(created|received|started|finished|canceled|errored)/

        def handle?
          repository.migrated_at
        end

        def handle
          Travis::Merge.import(type, object.id, event: event, src: :hub)
        end

        def type
          event.to_s.split(':').first
        end

        class Instrument < Addons::Instrument
          MSG = 'Notifying merge to import %s id=%s'

          def notify_completed
            publish(msg: MSG % [target.type, object.id])
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end
