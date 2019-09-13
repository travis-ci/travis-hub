require 'json'
require 'jwt'
require 'rack/ssl'
require 'sinatra/base'
require 'openssl'
require 'travis/hub/context'
require 'travis/hub/api/auth'
require 'travis/hub/api/jwt'
require 'travis/hub/api/sentry'
require 'travis/sidekiq'

module Travis
  module Hub
    class Api < Sinatra::Base
      STARTED_AT = Time.now

      configure do
        Hub.context = Hub::Context.new
        use Sentry if Hub.context.config.sentry.dsn
        use Hub::Auth, Hub.context.config.auth.to_h
        fail 'jwt rsa key is not set' unless Hub.context.config.auth.jwt_public_key
      end

      configure :production, :staging do
        use Rack::SSL
      end

      patch '/jobs/:id/state' do
        if update_state
          status 200
        else
          status 409
        end
        body JSON.dump(state: job.state)
      end

      # generates an JWT access token from the given refresh token, but only
      # does so once, based on a unique key stored in Redis by travis-build
      post '/jobs/:id/token' do
        validate_jwt!
        halt 401 unless refresh_token?
        token = Jwt::Refresh.new(config[:auth], request.env[:jwt_token], redis).run
        halt 403 unless token
        status 200
        body token
      end

      post '/jobs/:id/events' do
        validate_jwt!
        halt 401 unless access_token?
        data = JSON.parse(request.body.read)
        event, payload = data.values_at('event', 'payload')
        Travis::Sidekiq.hub(event, payload)
        status 200
      end

      get '/uptime' do
        status 200
        uptime.to_s
      end

      private

        EVENTS = {
          created:   :reset,
          received:  :receive,
          started:   :start,
          passed:    :finish,
          failed:    :finish,
          errored:   :finish,
          cancelled: :cancel
        }

        def update_state
          state = job.state
          return false if state == :canceled
          Service::UpdateJob.new(context, event, payload).run
          state != job.reload.state
        end

        def refresh_token?
          request.env[:jwt_auth].refresh?
        end

        def access_token?
          request.env[:jwt_auth].access?
        end

        def validate_jwt!
          ids = [request.env[:jwt_payload]['sub'], params[:id]]
          halt 403 unless ids.map(&:to_i).uniq.size == 1
        end

        def job
          @job ||= Job.find(params[:id])
        rescue ActiveRecord::RecordNotFound => e
          halt 404
        end

        def data
          @data ||= JSON.parse(request.body.read).map { |key, value| [key.to_sym, value] }.to_h
        end

        def event
          EVENTS[data[:new].to_s.to_sym] || fail("No :new state given")
        end

        def payload
          data.merge(id: params[:id], state: data[:new])
        end

        def uptime
          sec = Time.now - STARTED_AT
          sec.round
        end

        def config
          context.config
        end

        def redis
          context.redis
        end

        def context
          Travis::Hub.context
        end
    end
  end
end
