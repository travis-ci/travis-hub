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
        preload_constants!
        Travis::Hub.start
      end

      protected

        def preload_constants!
          require 'core_ext/module/load_constants'
          require 'travis'

          [Travis::Hub, Travis].each do |target|
            target.load_constants!(:skip => [/::AssociationCollection$/])
          end
        end
    end
  end
end
