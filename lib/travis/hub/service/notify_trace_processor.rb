module Travis
  module Hub
    module Service
      class NotifyTraceProcessor < Struct.new(:context)
        include Helper::Context

        MSGS = {
          notify: 'Notifying trace processor for <Job id=%s>',
          notify_failed: 'Trace processor notify failed for <Job id=%s> with error %s'
        }

        def notify(job, data)
          return unless ENV['TRACEPROC_ENABLED'] == 'true'
          return unless ENV['TRACEPROC_URL']
          return unless data[:trace]

          info :notify, job.id

          client.post do |req|
            req.url "/trace"
            req.params['source'] = 'hub'
            req.headers['Content-Type'] = 'application/json'
            req.body = {
              job_id:    job.id,
              repo_slug: job.repository.slug,
              owner:     job.owner.login,
              queue:     job.queue,
              state:     job.state
            }.to_json
          end
        rescue => e
          info :notify_failed, job.id, e
          Raven.capture_exception(e)
        end

        private

          def client
            @client ||= Faraday.new(url: url) do |c|
              c.basic_auth(*basic_auth)
              c.request :retry, max: 3, interval: 0.1, backoff_factor: 2
              c.adapter :net_http
            end
          end

          def url
            ENV['TRACEPROC_URL']
          end

          def basic_auth
            @basic_auth ||= begin
              parsed = URI(url)
              if parsed.user.nil? && parsed.password.nil?
                raise StandardError, 'Trace processor basic auth not set.'
              end

              [parsed.user, parsed.password]
            end
          end
      end
    end
  end
end
