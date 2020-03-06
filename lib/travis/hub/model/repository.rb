class Repository < ActiveRecord::Base
  has_many :builds

  def slug
    vcs_slug || [owner_name, name].join('/')
  end

  def migrating?
    migration_status == 'migrating'
  end
end
