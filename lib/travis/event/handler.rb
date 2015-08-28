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

        def notify(event, data = {})
          handler = new(event, data)
          handler.notify if handler.handle?
        end
      end

      attr_reader :event, :data

      def initialize(event, data = {})
        @event = event
        @data  = symbolize_keys(data)
      end

      def notify
        handle
      end
      instrument :notify
      rescues :notify, from: Exception

      private

        def object
          Kernel.const_get(object_type.camelize).find(data[:id])
        end

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
