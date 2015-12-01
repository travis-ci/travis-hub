require 'travis/hub/context'
require 'travis/hub/amqp/dispatcher'
require 'travis/hub/amqp/drain'
require 'travis/hub/amqp/solo'
require 'travis/hub/amqp/worker'

module Travis
  module Hub
    class Amqp
      MODES = { solo: Solo, worker: Worker, dispatcher: Dispatcher, drain: Drain }

      attr_reader :context, :processor

      def initialize(mode, options)
        @context   = Context.new
        @processor = MODES.fetch(mode).new(context, mode, options)
      end

      def run
        processor.run
      end
    end
  end
end
