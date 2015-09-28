require 'travis/support/logging'
require 'travis/support/instrumentation'
require 'travis/support/exceptions'

module Travis
  module Event
    class Handler
      include Logging
      extend  Instrumentation, Exceptions::Handling

      class << self
        def register(name, const)
          handlers[name.to_sym] = const
        end

        def handlers
          @@handlers ||= {}
        end

        def notify(event, params = {})
          handler = new(event, params)
          handler.notify if handler.handle?
        end
      end

      attr_reader :event, :params

      def initialize(event, params = {})
        @event  = event
        @params = symbolize_keys(params)
      end

      def notify
        handle
      end
      instrument :notify, on: [:completed, :failed]
      rescues :notify, from: Exception

      def object
        Kernel.const_get(object_type.camelize).find(params[:id])
      end

      private

        def object_type
          event.split(':').first
        end

        def action
          event.split(':').last.to_sym
        end

        def symbolize_keys(hash)
          Hash[hash.map { |key, value| [key.to_sym, value] }]
        end
    end
  end
end
