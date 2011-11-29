require 'bundler/setup'
require 'travis/hub'

$stdout.sync = true

module Travis
  module Tasks
    class Thor < ::Thor
      namespace 'travis:hub'

      desc 'start', 'Consume AMQP messages from the worker'
      method_option :env, :aliases => '-e', :default => ENV['RAILS_ENV'] || ENV['ENV'] || 'development'
      def start
        ENV['ENV'] = options['env']
        Travis::Hub.start
        puts 'started'
      end
    end
  end
end
