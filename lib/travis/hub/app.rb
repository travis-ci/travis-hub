require 'travis/hub/app/context'
require 'travis/hub/app/dispatcher'
require 'travis/hub/app/drain'
require 'travis/hub/app/handler'
require 'travis/hub/app/solo'
require 'travis/hub/app/worker'

module Travis
  module Hub
    class App
      MODES = { solo: Solo, worker: Worker, dispatcher: Dispatcher, drain: Drain }

      attr_reader :context, :processor

        def setup(context)
          Database.connect(config.database.to_h)
          Metrics.setup
          setup_amqp   unless context == :sidekiq
          setup_worker unless context == :dispatcher || context == :drain
        end

      def run
        context.setup
        processor.run
      end
    end
  end
end
