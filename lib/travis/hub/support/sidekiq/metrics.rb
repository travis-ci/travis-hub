require 'travis/support/metrics'

# TODO improve Travis::Metrics: add Metrics.time, add Metrics::Helpers

module Travis
  module Hub
    module Support
      module Sidekiq
        class Metrics
          def call(worker, message, queue, &block)
            name = worker.class.name.split("::").last.downcase
            meter(name)
            time(name, &block)
          rescue Exception
            meter("#{name}.failure")
            raise
          end

          private

            def time(name)
              started_at = Time.now
              yield
              meter("#{name}.perform", started_at: started_at, finished_at: Time.now)
            end

            def meter(name, options = {})
              Travis::Metrics.meter("sidekiq.jobs.#{name}", options)
            end
        end
      end
    end
  end
end
