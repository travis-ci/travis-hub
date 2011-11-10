module Travis
  class Hub
    module Processing
      autoload :Eventmachine, 'travis/hub/processing/eventmachine'
      autoload :Thread,       'travis/hub/processing/thread'

      class << self
        def start(&block)
          adapter.start(&block)
        end

        def run_periodically(interval, &block)
          adapter.run_periodically(interval, &block)
        end

        protected

          def adapter
            @adapter ||= RUBY_PLATFORM == 'java' ? Thread.new : EventMachine.new
          end
      end
    end
  end
end
