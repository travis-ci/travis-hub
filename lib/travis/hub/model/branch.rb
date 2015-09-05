class Branch < ActiveRecord::Base
  belongs_to :repository
  belongs_to :last_build, class_name: 'Build'

  def self.update_last_build(build)
    branch = where(repository_id: build.repository_id, name: build.branch || 'master').first_or_initialize
    branch.last_build = build
    branch.save!
  # TODO can we use INSERT [...] ON CONFLICT UPDATE instead?
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
