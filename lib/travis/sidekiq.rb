require 'sidekiq/pro/expiry'

module Travis
  module Sidekiq
    extend self

    def hub(*args)
      client.push(
        'queue' => 'hub',
        'class' => 'Travis::Hub::Sidekiq::Worker',
        'args'  => args
      )
    end

    def scheduler(*args)
      client.push(
        'queue'      => 'scheduler-2', # TODO use 'scheduler' once Scheduler 2.0 is fully rolled out
        'class'      => 'Travis::Scheduler::Worker',
        'args'       => [:event, *args],
        'expires_in' => 5 * 60 # TODO can be removed once Scheduler 2.0 picks these up
      )
    end

    def tasks(queue, name, *args)
      client.push(
        'queue'   => queue.to_s,
        'class'   => 'Travis::Async::Sidekiq::Worker',
        'args'    => [nil, "Travis::Addons::#{name}::Task", 'perform', *args]
      )
    end

    private

      def client
        ::Sidekiq::Client
      end
  end
end
