require 'openssl'
require 'base64'
require 'travis/encrypt'

# A Repository has an SSL key pair that is used to encrypt/decrypt sensitive
# data so it can be added to a public `.travis.yml` file (e.g. Campfire
# credentials).
class SslKey < ActiveRecord::Base
  include Travis::Encrypt::Helpers::ActiveRecord

  belongs_to :repository

  attr_encrypted :private_key

  def encode(string)
    Base64.encode64(encrypt(string)).strip
  end

  def encrypt(string)
    key.public_encrypt(string)
  end

  def decrypt(string)
    key.private_decrypt(string)
  end

  def secure
    Travis::SecureConfig.new(self)
  end

  private

    def key
      @key ||= OpenSSL::PKey::RSA.new(private_key)
    end
end
