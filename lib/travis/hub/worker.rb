module Travis
  module Hub
    class Worker < Solo
      def setup
        raise ArgumentError, 'missing worker number' unless count
        super
      end

      def queue
        "builds.#{count}"
      end

      def enqueue_jobs
        # handled by dispatcher
      end
    end
  end
end