require 'newrelic_rpm'
require 'travis/notifications'

module Travis
  class Hub
    module Monitoring
      def self.start
        puts "Starting New Relic with env: #{Travis.config.env}"

        # Add controller instrumentation to the AMQP message handlers
        Travis::Hub::Handler::Job.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:handle_log_update)
          add_transaction_tracer(:handle_update)
        end

        Travis::Hub::Handler::Worker.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:handle)
        end

        # Add task instrumentation to the background jobs
        Travis::Notifications::Handler::Pusher.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:push, :category => :task)
        end

        Travis::Notifications::Handler::Email.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:send_emails, :category => :task)
        end

        Travis::Notifications::Handler::Irc.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:send_irc_notifications, :category => :task)
        end

        Travis::Notifications::Handler::Campfire.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:send_campfire, :category => :task)
        end

        Travis::Notifications::Handler::Webhook.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:send_webhook, :category => :task)
        end

        patch_active_record_instrumentation_initialization

        NewRelic::Agent.manual_start(:env => Travis.config.env)

      rescue Exception => e
        puts 'New Relic Agent refused to start!', e.message, e.backtrace
      end

      # New Relic is doing some funky shit which means that I have
      # to do this myself for now, bigger explanation pending
      def self.patch_active_record_instrumentation_initialization
        # we need to require the full file path due to how new relic
        # does the same, making it harder for our patches to stick
        require gem_file_path('new_relic/agent/instrumentation/active_record')

        dependent = DependencyDetection.dependency_by_name(:active_record)

        executes = dependent.instance_variable_get(:'@executes')
        puts "[Monitoring] Removing #{executes.size} :active_record executes blocks"

        dependent.instance_variable_set(:'@executes', [])

        executes = dependent.instance_variable_get(:'@executes')
        puts "[Monitoring] #{executes.size} :active_record blocks remaining"

        dependent.executes do
          ActiveRecord::ConnectionAdapters::AbstractAdapter.module_eval do
            include ::NewRelic::Agent::Instrumentation::ActiveRecord
          end

          ActiveRecord::Base.class_eval do
            class << self
              add_method_tracer(:find_by_sql, 'ActiveRecord/#{self.name}/find_by_sql',
                                :metric => false)
              add_method_tracer(:transaction, 'ActiveRecord/#{self.name}/transaction',
                                :metric => false)
            end
          end
        end
      end

      def self.gem_file_path(file)
        Gem::Specification.find_by_path(file).gem_dir + '/lib/' + file + '.rb'
      end
    end
  end
end

