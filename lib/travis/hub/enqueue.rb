module Travis
  module Hub
    class Enqueue < Solo

      def run
        enqueue_jobs
      end

    end
  end
end
