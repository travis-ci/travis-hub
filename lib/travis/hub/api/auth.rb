# frozen_string_literal: true
require 'rack/auth/abstract/handler'
require 'rack/auth/abstract/request'

module Travis
  module Hub
    class Auth < Rack::Auth::AbstractHandler
      attr_reader :tokens

      def initialize(app, config = {}, alg = 'RS512')
        @app = app
        @alg = alg
        @key = OpenSSL::PKey::RSA.new(config[:jwt_public_key])
        @tokens = config[:http_basic_auth]
        @verify = true
      end

      attr_reader :alg, :key, :verify

      def call(env)
        auth = Request.new(env)

        return unauthorized unless auth.provided?
        return bad_request  unless auth.basic? || auth.bearer?

        if basic_valid?(auth)
          env['REMOTE_USER'] = auth.basic_username
          return @app.call(env)
        end

        unless decode_jwt(auth)
          return [403, { 'Content-Type' => 'text/plain', 'Content-Length' => '0' }, []]
        end

        bearer_valid?(auth) ? @app.call(env) : unauthorized
      end

      private

      def challenge
        'Basic realm="travis-hub"'
      end

      def basic_valid?(auth)
        user, password = auth.basic_credentials
        return unless user && password
        tokens[user.to_sym] == password
      end

      def bearer_valid?(auth)
        return false if auth.job_id.nil?
        return false if auth.params.empty?
        return false if auth.jwt_header.nil? || auth.jwt_payload.nil?
        true
      end

      def decode_jwt(auth)
        auth.jwt_payload, auth.jwt_header = JWT.decode(
          auth.params, key, verify,
          algorithm: alg, verify_sub: true, 'sub' => auth.job_id
        )
        true
      rescue JWT::InvalidSubError
        false
      rescue JWT::DecodeError
        false
      rescue JWT::ExpiredSignature
        false
      end

      class Request < Rack::Auth::AbstractRequest
        def job_id
          (%r{jobs/(\d+)}.match(request.path_info) || [])[1]
        end

        def basic?
          'basic' == scheme
        end

        def bearer?
          'bearer' == scheme
        end

        def basic_credentials
          @basic_credentials ||= params.unpack('m*').first.split(/:/, 2)
        end

        def basic_username
          basic_credentials.first
        end

        attr_accessor :jwt_payload, :jwt_header
      end
    end
  end
end
