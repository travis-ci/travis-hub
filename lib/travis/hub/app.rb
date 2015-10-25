require 'travis/hub/app/context'
require 'travis/hub/app/dispatcher'
require 'travis/hub/app/handler'
require 'travis/hub/app/solo'
require 'travis/hub/app/worker'

module Travis
  module Hub
    class App
      MODES = { solo: Solo, worker: Worker, dispatcher: Dispatcher }

      attr_reader :context, :processor

      def initialize(mode, options)
        Hub.context = @context = Context.new # TODO remove Hub.context
        @processor = MODES.fetch(mode).new(context, mode, options)
      end

      def run
        context.setup
        processor.run
      end
    end
  end
end
