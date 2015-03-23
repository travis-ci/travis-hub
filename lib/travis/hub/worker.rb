module Travis
  module Hub
    class Worker < Solo

      def run
        subscribe_to_queue
      end

    end
  end
end
