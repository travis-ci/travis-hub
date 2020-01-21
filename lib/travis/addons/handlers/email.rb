require 'travis/addons/handlers/base'
require 'travis/addons/handlers/notifier'
require 'travis/addons/model/broadcast'

module Travis
  module Addons
    module Handlers
      class Email < Notifiers
        EVENTS = 'build:finished'
        KEY = :email

        class Notifier < Notifier
          def handle?
            !pull_request? && config.enabled? && config.send_on?(:email, action) && recipients.present?
          end

          def handle
            Travis::Addons.logger.send(:info, "Email < Notifiers, handle payload: #{payload.to_s}")
            Travis::Addons.logger.send(:info, "Email < Notifiers, handle broadcasts: #{broadcasts.to_s}")
            run_task(:email, payload, recipients: recipients, broadcasts: broadcasts)
          end

          def recipients
            Travis::Addons.logger.send(:info, "Email < Notifiers, recipients>config: #{config.values(:recipients)}")
            Travis::Addons.logger.send(:info, "Email < Notifiers, recipients>configured_emails: #{configured_emails.to_s}")
            Travis::Addons.logger.send(:info, "Email < Notifiers, recipients>default_emails: #{default_emails.to_s}")
            Travis::Addons.logger.send(:info, "Email < Notifiers, recipients>unsubscribed_emails: #{unsubscribed_emails.to_s}")
            @recipients ||= begin
              emails = configured_emails || default_emails
              emails -= unsubscribed_emails
              emails - ::Email.joins(:user).where(email: emails).merge(User.with_preference(:build_emails, false)).pluck(:email).uniq
            end
          end

          private

            def configured_emails
              emails = config.values(:recipients)
              emails.try(:any?) && emails
            end

            def default_emails
              emails = [commit.author_email, commit.committer_email]
              Travis::Addons.logger.send(:info, "Email < Notifiers, emails: #{commit.author_email.to_s}, #{commit.committer_email.to_s}")
              user_ids = object.repository.permissions.pluck(:user_id)
              Travis::Addons.logger.send(:info, "Email < Notifiers, user_ids: #{user_ids}")
              Travis::Addons.logger.send(:info, "Email < Notifiers, result: #{::Email.where(email: emails, user_id: user_ids).pluck(:email).uniq.to_s}")
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
