require 'travis/addons/handlers/base'
require 'travis/addons/model/broadcast'

module Travis
  module Addons
    module Handlers
      class Email < Base
        EVENTS = 'build:finished'

        def handle?
          !pull_request? && config.enabled?(:email) && config.send_on?(:email, action) && recipients.present?
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

          def default_recipients
            emails = [commit.author_email, commit.committer_email]
            user_ids = object.repository.permissions.pluck(:user_id)
            ::Email.where(email: emails, user_id: user_ids).pluck(:email).uniq
          end

          def broadcasts
            msgs = Broadcast.by_repo(object.repository).pluck(:message)
            msgs.map { |msg| { message: msg } }
          end

          def normalize_array(array)
            Array(array).join(',').split(',').map(&:strip).select(&:present?).uniq
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
