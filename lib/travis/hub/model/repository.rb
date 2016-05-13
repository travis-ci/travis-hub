class Repository < ActiveRecord::Base
  has_many :builds
end
