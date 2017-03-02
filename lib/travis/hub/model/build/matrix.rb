class Build < ActiveRecord::Base
  class Matrix < Struct.new(:jobs, :config)
    def finished?
      jobs.all?(&:finished?) || fast_finish? && required.finished?
    end

    def passed?
      required.all?(&:passed?)
    end

    def restartable?
      jobs.any?(&:created?)
    end

    def duration
      jobs.map(&:duration).map(&:to_i).inject(&:+) if finished?
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
        raise InvalidMatrixState.new(jobs)
      end
    end

    def all?(&block)
      jobs.all?(&block)
    end

    private

      def required
        @required ||= Matrix.new(jobs.reject(&:allow_failure?))
      end

      def fast_finish?
        config = [self.config || {}].flatten.first
        !!config[:fast_finish] if config.is_a?(Hash) # TODO travis-yaml
      end
  end

  class InvalidMatrixState < StandardError
    ATTRS = %w(id state allow_failure created_at queued_at started_at finished_at canceled_at)

    attr_reader :jobs

    def initialize(jobs)
      @jobs = jobs
    end

    def to_s
      "Invalid build matrix state detected. Jobs:\n\t#{jobs.map { |job| format(job) }.join("\n")}"
    end

    private

      def format(job)
        ATTRS.map { |name| "#{name}: #{job.send(name).inspect}" }.join(', ')
      end
  end
end
