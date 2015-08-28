require 'travis/event/handler'
require 'travis/event/subscription'

module Travis
  module Event
    class << self
      def setup(handlers = nil)
        @handlers = handlers || []
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
          subscription = Subscription.new(name)
          subscription if subscription.subscriber
        end.compact
      end
    end

    def notify(event, *args)
      prefix = Underscore.new(self.class.name).string
      event  = PastTense.new(event).string
      Event.dispatch("#{prefix}:#{event}", id: id)
    end

    class PastTense < Struct.new(:string)
      def string
        "#{super}ed".gsub(/eded$|eed$/, 'ed')
      end
    end

    class Underscore < Struct.new(:string)
      def string
        super.gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase.tr('/', ':')
      end
    end
  end
end
