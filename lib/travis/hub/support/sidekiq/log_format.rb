module Travis
  module Support
    module Sidekiq
      class Logging < Struct.new(:config)
        def call(severity, time, progname, message)
          time      = config[:time_format] ? "#{time.strftime(config[:time_format])} " : nil
          proc_name = ENV['TRAVIS_PROCESS_NAME'] ? "#{severity[0, 1]} " : nil
          pid       = config[:process_id] ? "PID=#{Process.pid} " : nil
          tid       = config[:thread_id] ?  "TID=#{Thread.current.object_id} " : nil

          "#{time}#{severity[0, 1]} #{proc_name}#{pid}#{tid}#{context} #{message}\n"
        end

        private

          def context
            c = Thread.current[:sidekiq_context]
            c.join(' ') if c && c.any?
          end
      end
    end
  end
end
