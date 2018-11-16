require 'travis/encrypt'

class User < ActiveRecord::Base
  include Travis::Encrypt::Helpers::ActiveRecord

  class << self
    def with_github_token
      where("github_oauth_token IS NOT NULL and github_oauth_token != ''")
    end

    def with_permissions(permissions)
      where(:permissions => permissions).includes(:permissions)
    end

    def with_preference(preference, value)
      where(["preferences->>? = ?", preference.to_s, value.to_s])
    end
  end

  has_many :permissions
  has_many :repositories, through: :permissions
  has_one :installation, as: :owner

  attr_encrypted :github_oauth_token
end
