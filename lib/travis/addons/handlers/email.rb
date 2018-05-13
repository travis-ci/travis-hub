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
          run_task(:email, payload, recipients: recipients, broadcasts: broadcasts)
        end

        def recipients
          @recipients ||= begin
            recipients = config.values(:email, :recipients)
            recipients.try(:any?) ? recipients : [creator]
          end
        end

        private

          def creator
            sender = object.sender

            unless sender.is_a?(User)
              warn "no recipient found: build event creator was not a user"
              return
            end

            unless sender.first_logged_in_at?
              warn "no recipient found: build event creator (#{sender.login}) has not signed up"
              return
            end

            unless sender.email?
              warn "no recipient found: build event creator (#{sender.login}) do not have an email in the system"
              return
            end

            sender.email
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
              publish(recipients: handler.recipients)
            end
          end
          EventHandler.attach_to(self)
      end
    end
  end
end
