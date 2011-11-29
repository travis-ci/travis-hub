require 'bundler/setup'
require 'travis/hub'
require 'newrelic_rpm'

$stdout.sync = true

module Travis
  module Tasks
    class Thor < ::Thor
      namespace 'travis:hub'

      desc 'start', 'Consume AMQP messages from the worker'
      method_option :env, :aliases => '-e', :default => ENV['RAILS_ENV'] || ENV['ENV'] || 'development'
      def start
        ENV['ENV'] = options['env']

        begin
          puts "Starting New Relic with env:#{options[:env]}"
          NewRelic::Agent.manual_start(:env => options['env'])
        rescue Exception => e
          puts 'New Relic Agent refused to start!'
          puts e.message
          puts e.backtrace
        end

        Travis::Hub.start
      end
    end
  end
end
