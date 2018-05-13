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
            unless sender.is_a?(User)
              no_recipient_warning "build creator was not a user"
              return
            end

            unless sender.first_logged_in_at?
              no_recipient_warning "build creator (#{sender.login}) has not signed up"
              return
            end

            unless permissions?
              no_recipient_warning "build creator (#{sender.login}) does not have permissions on this repository"
              return
            end

            unless sender.email?
              no_recipient_warning "build creator (#{sender.login}) do not have an email in the system"
              return
            end

            sender.email
          end

          def no_recipient_warning(desc)
            msg = "#{self.class.to_s} build=#{object.id} status=no_recipient message=\"#{desc}\""
            Addons.logger.warn(msg)
          end
          
          def sender
            object.sender
          end

          def permissions?
            object.repository.permissions.where(user_id: object.sender.id).exists?
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
