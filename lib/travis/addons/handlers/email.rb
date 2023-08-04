require 'travis/addons/handlers/base'
require 'travis/addons/handlers/notifier'
require 'travis/addons/model/broadcast'

module Travis
  module Addons
    module Handlers
      class Email < Notifiers
        EVENTS = /build:(finished|canceled)/
        KEY = :email

        class Notifier < Notifier
          def handle?
            !pull_request? && config.enabled? && config.send_on?(:email, action) && recipients.present? && !config[:auto_canceled?]
          end

          def handle
            run_task(:email, payload, recipients:, broadcasts:)
          end

          def recipients
            @recipients ||= begin
              emails = configured_emails || default_emails
              emails -= unsubscribed_emails
              # emails - ::Email.joins(:user).where(email: emails).merge(User.with_preference('build_emails', false)).pluck(:email).uniq
              emails -= no_build_emails(emails)
              emails
            end
          end

          private

          def no_build_emails(emails)
            ::Email.joins(:user).where(email: emails).select do |obj|
              user = User.find(obj.user_id)
              preferences = JSON.parse(user.preferences) if user.preferences.is_a?(String)
              preferences['build_emails'] == false
            end.map!(&:email)
          end

          def configured_emails
            emails = config.values(:recipients)
            emails.try(:any?) && emails
          end

          def default_emails
            emails = [commit.author_email, commit.committer_email]
            user_ids = object.repository.permissions.pluck(:user_id)
            ::Email.where(email: emails, user_id: user_ids).pluck(:email).uniq
          end

          def unsubscribed_emails
            user_ids = object.repository.email_unsubscribes.pluck(:user_id)
            ::Email.where(user_id: user_ids).pluck(:email).uniq
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
end
