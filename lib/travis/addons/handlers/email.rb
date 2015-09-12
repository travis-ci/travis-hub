require 'travis/addons/handlers/base'
require 'travis/addons/model/broadcast'

module Travis
  module Addons
    module Handlers
      class Email < Base
        EVENTS = 'build:finished'

        def handle?
          !pull_request? && enabled? && send? && recipients.present?
        end

        def handle
          run_task(:email, payload, recipients: recipients, broadcasts: broadcasts)
        end

        def recipients
          @recipients ||= begin
            recipients = config.values(:email, :recipients)
            recipients.try(:any?) ? recipients : default_recipients
          end
        end

        private

          def enabled?
            config.enabled?(:email)
          end

          def send?
            config.send_on?(:email, action)
          end

          def broadcasts
            Broadcast.by_repo(object.repository).pluck(:message)
          end

          def default_recipients
            emails = [commit.author_email, commit.committer_email]
            ::Email.where(email: emails).pluck(:email).uniq
          end

          class EventHandler < Addons::Instrument
            def notify_completed
              publish(:recipients => handler.recipients)
            end
          end
          EventHandler.attach_to(self)
      end
    end
  end
end
