require 'newrelic_rpm'
require 'travis/notifications'

module Travis
  class Hub
    module Monitoring
      def self.start
        puts "Starting New Relic with env: #{Travis.env}"

        # Add controller instrumentation to the AMQP message handlers
        Travis::Hub::Handler::Configure.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:handle, :request => nil)
        end

        Travis::Hub::Handler::Job.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:handle_log_update, :request => nil)
          add_transaction_tracer(:handle_update, :request => nil)
        end

        Travis::Hub::Handler::Request.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:handle, :request => nil)
        end

        Travis::Hub::Handler::Worker.class_eval do
          include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer(:handle, :request => nil)
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

        NewRelic::Agent.manual_start(:env => Travis.env)

      rescue Exception => e
        puts 'New Relic Agent refused to start!', e.message, e.backtrace
      end
    end
  end
end

