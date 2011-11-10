require 'eventmachine'

module Travis
  module Hub
    class Processing
      class EventMachine
        def start(&block)
          ::EventMachine.start(&block)
        end

        def run_periodically(interval, &block)
          ::EventMachine.add_periodic_timer(interval, &block)
        end
      end
    end
  end
end


