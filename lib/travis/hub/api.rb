require 'json'
require 'jwt'
require 'rack/ssl'
require 'sinatra/base'
require 'openssl'
require 'travis/hub/context'
require 'travis/hub/api/auth'
require 'travis/hub/api/sentry'

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

      get '/uptime' do
        status 200
        uptime.to_s
      end

      private

        EVENTS = {
          created:  :reset,
          received: :receive,
          started:  :start,
          passed:   :finish,
          failed:   :finish,
          errored:  :finish
        }

        def update_state
          state = job.state
          return false if state == :canceled
          Service::UpdateJob.new(context, event, payload).run
          state != job.reload.state
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

        def context
          Travis::Hub.context
        end
    end
  end
end
