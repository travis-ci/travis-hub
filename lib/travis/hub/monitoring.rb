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
        Travis::Notifications::Pusher.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:push, :category => :task)
        end

        Travis::Notifications::Email.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:send_emails, :category => :task)
        end

        Travis::Notifications::Irc.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:send_irc_notifications, :category => :task)
        end

        Travis::Notifications::Campfire.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:send_webhook_notifications, :category => :task)
        end

        Travis::Notifications::Webhook.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:send_webhook_notifications, :category => :task)
        end

        NewRelic::Agent.manual_start(:env => Travis.config.env)

      rescue Exception => e
        puts 'New Relic Agent refused to start!', e.message, e.backtrace
      end
    end
  end
end

