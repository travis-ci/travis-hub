require 'travis/instrumentation'
require 'travis/exceptions'
require 'travis/event/error'

module Travis
  module Event
    class Handler
      extend  Instrumentation

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
      rescue Exception => e
        Exceptions.handle(Error.new(e, event, params)) # TODO pass in
      end
      instrument :notify, on: [:completed, :failed]

      def object
        @object ||= begin
          obj = Kernel.const_get(object_type.camelize).find(params[:id])
          obj.assign_attributes(params[:attrs]) if params[:attrs]
          obj
        end
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
