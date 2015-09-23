require 'sidekiq'

module Travis
  module Addons
    module Helpers
      def run_task(queue, *args)
        # ::Sidekiq::Client.push(
        #   'queue'   => queue,
        #   'class'   => "Travis::Addons::#{self.class.name.split('::').last}::Task",
        #   'method'  => 'perform',
        #   # 'args'    => [event, id: object.id],
        #   'args'    => [*args]
        # )

        target = "Travis::Addons::#{self.class.name.split('::').last}::Task"
        ::Sidekiq::Client.push(
          'queue'   => queue,
          'class'   => 'Travis::Async::Sidekiq::Worker',
          'args'    => [nil, target, 'perform', *args]
        )
      end
    end
  end
end
