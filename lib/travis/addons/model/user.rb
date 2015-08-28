class User < ActiveRecord::Base
  has_many :permissions
  has_many :repositories, through: :permissions
  # has_many :emails

  class << self
    def with_github_token
      where("github_oauth_token IS NOT NULL and github_oauth_token != ''")
    end

    def with_permissions(permissions)
      where(:permissions => permissions).includes(:permissions)
    end
  end
end
