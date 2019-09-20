require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'
require 'travis/addons/model/broadcast'

module Travis
  module Addons
    module Handlers
      class Email < Base
        include Handlers::Task

        EVENTS = 'build:finished'

        def handle?
          !pull_request? && config.enabled?(:email) && config.send_on?(:email, action) && config.notifications.any? {|cfg| recipients(cfg).present?}
        end

        def handle
          config.notifications.each do |cfg|
            run_task(:email, payload, recipients: recipients(cfg), broadcasts: broadcasts)
          end
        end

        def recipients(cfg)
          emails = configured_emails(cfg) || default_emails(cfg)
          emails - ::Email.joins(:user).where(email: emails).merge(User.with_preference(:build_emails, false)).pluck(:email).uniq
        end

        private

          def configured_emails(cfg)
            emails = read_recipients(cfg, :email, :recipients)
            emails.try(:any?) && emails
          end

          def default_emails(cfg)
            emails = [commit.author_email, commit.committer_email]
            user_ids = object.repository.permissions.pluck(:user_id)
            user_ids -= object.repository.email_unsubscribes.pluck(:user_id)
            ::Email.where(email: emails, user_id: user_ids).pluck(:email).uniq
          end

          def broadcasts
            msgs = Broadcast.by_repo(object.repository).pluck(:message, :category)
            msgs.map { |msg, cat| { message: msg, category: cat } }
          end

          def normalize_array(array)
            Array(array).join(',').split(',').map(&:strip).select(&:present?).uniq
          end

          def read_recipients(cfg, type, key)
            # notifications.map do |notifier|
              config = cfg[type] rescue {}
              value  = config.is_a?(Hash) ? config[key] : config
              value.is_a?(Array) || value.is_a?(String) ? normalize_array(value) : value
            # end
          end

          class EventHandler < Addons::Instrument
            def notify_completed
              publish(recipients: handler.recipients)
            end
          end
          EventHandler.attach_to(self)
      end
    end
  end
end
