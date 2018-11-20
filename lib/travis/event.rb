require 'travis/event/handler'
require 'travis/event/helpers'
require 'travis/event/subscription'

module Travis
  module Event
    class << self
      attr_reader :logger

      def setup(handlers = [], logger = nil)
        @logger = logger
        @handlers = handlers
      end

      def handlers
        @handlers || fail('Call Travis::Event.setup to set event handlers')
      end

      def dispatch(event, data)
        subscriptions.each do |subscription|
          subscription.notify(event, data)
        end
      end

      def subscriptions
        @subscriptions ||= handlers.map do |name|
          subscription = Subscription.new(name, logger)
          subscription if subscription.subscriber
        end.compact
      end
    end

    def notify(event, *args)
      prefix = Underscore.new(self.class.name).string
      event  = PastTense.new(event).string
      Event.dispatch("#{prefix}:#{event}", id: id, attrs: attributes)
    end
  end
end
