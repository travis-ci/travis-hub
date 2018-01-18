module Travis
  module Instrumentation
    module Publisher
      class Log
        attr_reader :logger

        def initialize(logger = nil)
          @logger = logger
        end

        def publish(event)
          level = event.key?(:exception) ? :error : :info
          message = event[:message]
          message = "#{message} (#{'%.5f' % event[:duration]}s)" if event[:duration]
          log(level, message)

          if level == :error || logger.level == ::Logger::DEBUG
            event.each do |key, value|
              next if key == :message
              level = event.key?(:exception) ? :error : :debug
              log(level, "  #{key}: #{value.inspect}")
            end
          end
        end

        def log(level, msg)
          logger.send(level, msg)
        end
      end
    end
  end
end
