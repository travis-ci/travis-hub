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
    end
  end
end