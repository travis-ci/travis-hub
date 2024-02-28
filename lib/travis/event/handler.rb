require 'travis/instrumentation'
require 'travis/exceptions'
require 'travis/event/error'

module Travis
  module Event
    class Handler
      extend Instrumentation

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
        Exceptions.handle(Error.new(e, event, params)) # TODO: pass in
      end
      instrument :notify, on: %i[completed failed]

      def object
        @object ||= begin
          obj = Kernel.const_get(object_type.camelize).find(params[:id])
          if params[:attrs]
            params[:attrs].each do |k,v|
              obj.assign_attributes(k => v) if v
            end
          end
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
