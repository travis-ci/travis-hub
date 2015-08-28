require 'travis/hub/model/repository'

Repository.class_eval do
  belongs_to :owner, polymorphic: true
  has_many   :permissions
  has_many   :users, through: :permissions
  has_one    :key, class_name: 'SslKey'

  def slug
    @slug ||= [owner_name, name].join('/')
  end
end
