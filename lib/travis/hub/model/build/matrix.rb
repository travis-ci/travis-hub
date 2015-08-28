class Build < ActiveRecord::Base
  class Matrix < Struct.new(:jobs, :config)
    def finished?
      jobs.all?(&:finished?) || fast_finish? && required.unsuccessful?
    end

    def unsuccessful?
      jobs.any?(&:finished_unsuccessfully?)
    end

    def duration
      finished? ? jobs.inject(0) { |duration, job| duration + job.duration.to_i } : nil
    end

    def state
      if required.jobs.blank?
        :passed
      elsif required.jobs.any?(&:canceled?)
        :canceled
      elsif required.jobs.any?(&:errored?)
        :errored
      elsif required.jobs.any?(&:failed?)
        :failed
      elsif required.jobs.all?(&:passed?)
        :passed
      else
        raise InvalidMatrixStateException.new(jobs)
      end
    end

    private

      def required
        @required ||= Matrix.new(jobs.reject { |test| test.allow_failure? })
      end

      def fast_finish?
        config = config || {}
        config = {} if config.is_a?(Array)
        !!config[:fast_finish]
      end

      class InvalidMatrixStateException < StandardError
        ATTRS = %w(id state allow_failure created_at queued_at started_at finished_at canceled_at)

        attr_reader :jobs

        def initialize(jobs)
          @jobs = jobs
        end

        def to_s
          "Invalid build matrix state detected. Jobs:\n\t#{jobs.map { |job| format(job) }.join}"
        end

        private

          def format(job)
            ATTRS.map { |name| "#{name}: #{job.send(name)}" }.join(', ')
          end
      end
  end
end
