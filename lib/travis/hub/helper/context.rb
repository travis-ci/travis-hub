module Travis
  module Hub
    module Helper
      module Context
        attr_reader :context

        def initialize(context, *args)
          fail "First argument to #{self.class.name}.new must be an instance of Context. #{context.class.name} given." unless context.is_a?(Hub::Context)
          @context = context
          super(*args)
        end

        def config
          context.config
        end

        def logger
          context.logger
        end

        def metrics
          context.metrics
        end

        def redis
          context.redis
        end

        [:info, :warn, :debug, :error, :fatal].each do |level|
          define_method(level) { |msg, *args| log(level, msg, *args) }
        end

        def log(level, msg, *args)
          logger.send(level, msg.is_a?(::String) ? msg : self.class::MSGS[msg] % args)
        end

        def handle_exception(*args)
          # context.exceptions.handle(*args)
          Exceptions.handle(*args)
        end

        def meter(key)
          metrics.meter(key)
        end

        def timer(key, duration)
          Metriks.timer(key).update(duration)
        end
      end
    end
  end
end
