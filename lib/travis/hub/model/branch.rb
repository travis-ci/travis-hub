class Branch < ActiveRecord::Base
  belongs_to :repository
  belongs_to :last_build, class_name: 'Build'
end
