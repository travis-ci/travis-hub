require 'base64'

module Jwt
  class Refresh < Struct.new(:config, :token, :redis)
    include Base64

    MAX_DURATION = 10800
    ALG = 'RS512'

    def run
      access_token.encode if valid?
    end

    def valid?
      return false unless refresh_token.valid?
      return false unless redis.exists(refresh_key)
      redis.del(refresh_key)
      true
    end

    def refresh_key
      @refresh_key ||= ['jwt-refresh', refresh_token.sub, refresh_token.rand].join(':')
    end

    def refresh_token
      @refresh_token ||= RefreshToken.new(token, private_key)
    end

    def access_token
      AccessToken.new(refresh_token.sub, refresh_token.site, private_key)
    end

    def private_key
      OpenSSL::PKey::RSA.new(config[:jwt_private_key])
    end

    class RefreshToken < Struct.new(:token, :key)
      attr_reader :payload, :headers

      def initialize(*)
        super
        @payload, @headers = decode
      end

      def valid?
        !!payload
      end

      def sub
        payload['sub']
      end

      def site
        payload['site']
      end

      def rand
        payload['rand']
      end

      def decode
        JWT.decode(token, key, true, algorithm: ALG, verify_sub: true)
      end
    end

    class AccessToken < Struct.new(:sub, :site, :key)
      def encode
        JWT.encode(payload, key, ALG)
      end

      def payload
        {
          iss: 'hub',
          typ: 'access',
          sub: sub,
          exp: expires.to_i,
          site: site
        }
      end

      def expires
        Time.now.utc + MAX_DURATION
      end
    end
  end
end
