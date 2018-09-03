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
          !pull_request? && config.enabled?(:email) && config.send_on?(:email, action) && recipients.present?
        end

        def handle
          run_task(:email, payload, recipients: recipients, broadcasts: broadcasts, configured: !!configured_emails)
        end

        def recipients
          configured_emails || subscribed_emails
        end

        private

          def configured_emails
            @recipients ||= begin
              recipients = config.values(:email, :recipients)
              recipients.try(:any?) && recipients
            end
          end

          def subscribed_emails
            emails = [commit.author_email, commit.committer_email]
            user_ids = object.repository.permissions.pluck(:user_id)
            user_ids -= object.repository.email_unsubscribes.pluck(:user_id)
            user_ids -= User.where(id: user_ids).with_preference(:build_emails, false).pluck(:id)
            ::Email.where(email: emails, user_id: user_ids).pluck(:email).uniq
          end

          def broadcasts
            msgs = Broadcast.by_repo(object.repository).pluck(:message, :category)
            msgs.map { |msg, cat| { message: msg, category: cat } }
          end

          def normalize_array(array)
            Array(array).join(',').split(',').map(&:strip).select(&:present?).uniq
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
