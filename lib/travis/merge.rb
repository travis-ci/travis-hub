require 'faraday_middleware'

module Travis
  module Merge
    extend self

    def import(type, id, args)
      http.post([type, id, 'import'].join('/'), args)
    end

    private

      def http
        Faraday.new(url: url) do |c|
          c.request :authorization, :token, token
          c.request :retry, max: 5, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2
          c.request :json
          c.response :raise_error
          c.adapter :net_http
        end
      end

      def url
        ENV['MERGE_API_URL'] || 'https://travis-merge-pipe-staging.herokuapp.com/api'
      end

      def token
        ENV['MERGE_API_TOKEN'] || raise('no merge api token given')
      end
  end
end
