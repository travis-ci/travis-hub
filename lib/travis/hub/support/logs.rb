require 'faraday'

module Travis
  class Logs < Struct.new(:config, :logger)
    def put(id, log)
      client.put("logs/#{id}", log)
    rescue => e
      # TODO should these go through Sidekiq so we can retry them more easily?
      logger.error "PUT to logs/#{id} failed: #{e.message}. Failed to create or update log."
    end

    private

      def client
        Faraday.new(url: url, headers: { authorization: token }) do |c|
          c.request  :retry, max: 8, interval: 0.1, backoff_factor: 2
          c.response :raise_error
          c.adapter  :net_http
        end
      end

      def url
        config[:url]
      end

      def token
        "token #{config[:token]}"
      end
  end
end
