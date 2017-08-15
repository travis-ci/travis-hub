require 'faraday'

module Travis
  module Hub
    module Support
      class JobBoard < Struct.new(:config)
        def cancel(id)
          client.delete do |req|
            req.url "jobs/#{id}"
            req.params['source'] = 'hub'
            req.headers['Travis-Site'] = site
            req.body = nil
          end
        end

        private

          def client
            @client ||= Faraday.new(url: url) do |c|
              c.basic_auth(*basic_auth)
              c.request :retry, max: 3, interval: 0.1, backoff_factor: 2
              c.adapter :net_http
            end
          end

          def site
            config[:site] || raise(StandardError, 'Job Board site not set.')
          end

          def url
            config[:url] || raise(StandardError, 'Job Board URL not set.')
          end

          def basic_auth
            return @basic_auth if defined?(@basic_auth)

            parsed = URI(url)
            if parsed.user.nil? && parsed.password.nil?
              raise StandardError, 'Job Board basic auth not set.'
            end

            @basic_auth = [parsed.user, parsed.password]
          end
      end
    end
  end
end
