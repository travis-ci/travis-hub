require 'newrelic_rpm'
require 'travis/event'

module Travis
  class Hub
    module NewRelic
      module Instrumentation
        class NewRelicProxy
          include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
        end

        def add_transaction_tracer(*names)
          options = names.last.is_a?(Hash) ? names.pop : {}

          include do
            def new_relic
              @new_relic ||= NewRelicProxy.new
            end

            names.each do |name|
              define_method(name) do |*args, &block|
                new_relic.perform_action_with_newrelic_trace(options.merge(:class_name => self.class.name, :name => name.to_s)) do
                  super(*args, &block)
                end
              end
            end
          end
        end
      end

      def self.start
        puts "Starting New Relic with env: #{Travis.env}"

        # Add controller instrumentation to the AMQP message handlers
        # These will be categorized as "background tasks" on new relic.
        Travis::Hub::Handler::Configure.class_eval do
          extend Instrumentation
          add_transaction_tracer :handle
        end

        Travis::Hub::Handler::Job.class_eval do
          extend Instrumentation
          add_transaction_tracer :handle_log_update, :handle_update
        end

        Travis::Hub::Handler::Request.class_eval do
          extend Instrumentation
          add_transaction_tracer :handle
        end

        Travis::Hub::Handler::Worker.class_eval do
          extend Instrumentation
          add_transaction_tracer :handle
        end

        # Add task instrumentation to the notification handlers
        # These will be categorized as "background tasks" on new relic.
        Travis::Event::Handler::Archive.class_eval do
          extend Instrumentation
          add_transaction_tracer :archive, :category => :task
        end

        Travis::Event::Handler::Email.class_eval do
          extend Instrumentation
          add_transaction_tracer :send_emails, :category => :task
        end

        Travis::Event::Handler::Irc.class_eval do
          extend Instrumentation
          add_transaction_tracer :send_irc_notifications, :category => :task
        end

        Travis::Event::Handler::Campfire.class_eval do
          extend Instrumentation
          add_transaction_tracer :send_campfire, :category => :task
        end

        Travis::Event::Handler::Pusher.class_eval do
          extend Instrumentation
          add_transaction_tracer :send_emails, :category => :task
        end

        Travis::Event::Handler::Webhook.class_eval do
          extend Instrumentation
          add_transaction_tracer :send_webhook, :category => :task
        end

        ::NewRelic::Agent.manual_start(:env => Travis.env)

      rescue Exception => e
        puts 'New Relic Agent refused to start!', e.message, e.backtrace
      end
    end
  end
end

