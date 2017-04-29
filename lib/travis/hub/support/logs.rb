require 'faraday'

module Travis
  module Hub
    module Support
      class Logs < Struct.new(:config)
        def update(id, msg, clear: false)
          client.put do |req|
            req.url "/logs/#{id}"
            req.params['clear'] = '1' if clear
            req.headers['Content-Type'] = 'application/octet-stream'
            req.body = msg
          end
        end

        def append_log_part(id, part, final: false)
          client.put do |req|
            req.url "/log-parts/#{id}/last"
            req.headers['Content-Type'] = 'application/json'
            req.body = JSON.dump(
              '@type' => 'log_part',
              'encoding' => 'base64',
              'content' => Base64.encode64(part),
              'final' => final
            )
          end
        end

        private

          def client
            @client ||= Faraday.new(url: url) do |c|
              c.request :authorization, :token, token
              c.request :retry, max: 5, interval: 0.1, backoff_factor: 2
              c.response :raise_error
              c.adapter :net_http
            end
          end

          def url
            config[:url] || raise('Logs URL not set.')
          end

          def token
            config[:token] || raise('Logs token not set.')
          end
      end
    end
  end
end
