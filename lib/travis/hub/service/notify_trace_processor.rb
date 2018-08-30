require 'travis/hub/support/job_board'

module Travis
  module Hub
    module Service
      class NotifyTraceProcessor < Struct.new(:context)
        include Helper::Context

        MSGS = {
          notify: 'Notifying trace processor for <Job id=%s>',
          notify_failed: 'Trace processor notify failed for <Job id=%s> with error %s'
        }

        def notify(data)
          return unless config[:enabled]
          return unless data[:trace]

          info :notify, data[:id]

          client.post do |req|
            req.url "/trace"
            req.params['source'] = 'hub'
            req.headers['Content-Type'] = 'application/json'
            req.headers['Authorization'] = "token #{config[:token]}"
            req.body = { job_id: data[:id] }.to_json
          end
        rescue => e
          info :notify_failed, data[:id], e
          Raven.capture_exception(e)
        end

        private

          def client
            @client ||= Faraday.new(url: url) do |c|
              c.request :retry, max: 3, interval: 0.1, backoff_factor: 2
              c.adapter :net_http
            end
          end

          def url
            config[:url]
          end

          def config
            @config ||= context.config.trace_processor.to_h
          end
      end
    end
  end
end
