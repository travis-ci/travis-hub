require 'active_support/inflector/inflections.rb'
# require 'metriks'

module Travis
  module Event
    class Subscription
      attr_reader :name, :logger

      def initialize(name, logger)
        name = 'github_status' if name == 'github_commit_status' # TODO compat, remove once configs have been updated
        @name = name
        @logger = logger
      end

      def subscriber
        Handler.handlers[name.to_sym] || missing_handler && nil
      end

      def notify(event, data)
        if matches?(event)
          subscriber.notify(event, data)
          # meter(event)
        end
      end

      private

        def patterns
          subscriber ? Array(subscriber::EVENTS) : []
        end

        def matches?(event)
          patterns.any? { |pattern| pattern.is_a?(Regexp) ? pattern.match(event) : pattern == event }
        end

        # def meter(event)
        #   metric = "travis.notifications.#{name}.#{event.gsub(/:/, '.')}"
        #   Metriks.meter(metric).mark
        # end

        def missing_handler
          logger.error("Could not find event handler #{name.inspect}, ignoring.")
        end
    end
  end
end

