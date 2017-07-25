require 'travis/instrumentation/instrument'

module Travis
  module Addons
    class Instrument < Instrumentation::Instrument
      attr_reader :handler, :object, :args, :result

      def initialize(message, method, status, payload)
        @handler, @args, @result = payload.values_at(:target, :args, :result)
        @object = handler.object
        super
      end

      def notify_completed
        publish
      end

      def publish(event = {})
        event = event.reverse_merge(
          :msg => "(#{handler.event}) for #{serialize(object)}",
          :object_type => object.class.name,
          :object_id => object.id,
          :event => handler.event
        )

        event[:payload]    = payload
        event[:request_id] = request_id
        event[:repository] = repo
        super(event)
      end

      private

        def serialize(object)
          # TODO this does not add all the stuff that is added on the subclasses (e.g. webhook targets)
          pairs = { id: object.id }
          pairs[:number] = object.number if object.respond_to?(:number)
          pairs[:state] = object.state if object.respond_to?(:state)
          pairs[:repo] = repo.slug if repo
          "#<#{object.class.name} #{pairs.map { |key, value| [key, value].join('=') }.join(' ')}>"
        end

        def payload
          handler.payload if handler.respond_to?(:payload)
        end

        def repo
          object.repository if object.respond_to?(:repository)
        end

        def request_id
          object.request_id if object.respond_to?(:request_id)
        end
    end
  end
end
