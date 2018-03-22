require 'sidekiq/pro/expiry'

module Travis
  module Merge
    extend self

    URL = 'https://travis-merge-staging.herokuapp.com'

    def import(type, id, *args)
      http.put([type, id].join('/'), args)
    end

    private

      def http
        Faraday.new(url: URL) do |c|
          c.request :authorization, :token, token
          c.request :retry, max: 5, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2
          c.response :raise_error
          c.adapter :net_http
        end
      end

      def token
        ENV['MERGE_API_TOKEN'] || raise('no merge api token given')
      end
  end
end
