require 'faraday'

module Travis
  class Logs < Struct.new(:config)
    def update(id, msg)
      http.put("/logs/#{id}", msg)
    end

    private

      def http
        Faraday.new(url: url) do |c|
          c.request  :authorization, :token, token
          c.request  :retry, max: 5, interval: 0.1, backoff_factor: 2
          c.response :raise_error
          c.adapter  :net_http
        end
      end

      def url
        config.url || raise('Logs URL not set.')
      end

      def token
        config.token || raise('Logs token not set.')
      end
  end
end
