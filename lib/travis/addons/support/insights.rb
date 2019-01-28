require 'faraday'

module Travis
  class Insights < Struct.new(:config)
    def post(data)
      http.post do |r|
        r.url '/events'
        r.params['source'] = 'hub'
        r.headers['Content-Type'] = 'application/json'
        r.body = JSON.dump(data)
      end
    end

    private

      def http
        @http ||= Faraday.new(compact(url: url, ssl: ssl)) do |c|
          c.request :authorization, :Token, %(token="#{token}")
          c.request :retry, max: 5, methods: [:post], exceptions: [Faraday::Error]
          c.response :raise_error
          c.adapter :net_http
        end
      end

      def url
        config[:insights][:url]
      end

      def token
        config[:insights][:token]
      end

      def ssl
        config[:ssl].to_h
      end

      def compact(hash)
        hash.reject { |_, value| value.nil? || value&.empty? }
      end
  end
end
