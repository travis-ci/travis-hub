require 'faraday'

module Travis
  module Hub
    module Support
      class JobBoard < Struct.new(:url)
        def remove(job_id)
          return if job_id.nil?
          client.delete do |req|
            req.url "/jobs/#{job_id}"
            req.params['source'] = 'hub'
          end
        rescue => e
          puts e.message, e.backtrace
        end

        private

          def client
            @conn ||= Faraday.new(url: url) do |c|
              c.request :authorization, :basic, url.user, url.password
              c.request :retry, max: 5, interval: 0.1, backoff_factor: 2
              c.response :raise_error
              c.adapter :net_http
            end
          end
      end
    end
  end
end
