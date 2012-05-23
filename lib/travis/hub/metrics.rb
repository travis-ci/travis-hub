require 'active_support/notifications'
require 'metriks'

module Travis
  module Hub
    class Metrics
      delegate :subscribe, :to => ActionSupport::Notifications

      def self.setup_subscriptions
        new.setup_subscriptions
      end

      def setup_subscriptions
        subscribe(/(load|http)\.gh/) do |*args|
          name, start, ending, transaction_id, payload = *args
          time = ending - start
          Metriks.timer(name).update(time)
        end
      end
    end
  end
end
