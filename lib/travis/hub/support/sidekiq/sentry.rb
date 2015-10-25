require 'raven'

# TODO should be using Travis::Exceptions.handle, because enterprise, right?

module Travis
  module Hub
    module Support
      module Sidekiq
        class Sentry
          attr_writer :raven

          def call(worker, message, queue)
            begin
              yield
            rescue Exception => error
              dispatch(error, queue: queue, worker: worker.to_s, env: Travis.env)
              raise
            end
          end

          def dispatch(error, extra)
            event = Raven::Event.capture_exception(error) do |event|
              event.extra = extra
            end
            raven.send(event)
          rescue Exception => e
            Travis.logger.error("Sending error to Sentry failed: #{e.message}")
            Travis.logger.error(e.backtrace.join("\n"))
          end

          def raven
            @raven ||= Raven
          end
        end
      end
    end
  end
end
