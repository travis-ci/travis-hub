class Branch < ActiveRecord::Base
  belongs_to :repository
  belongs_to :last_build, class_name: 'Build'

  def self.update_last_build(repo_id, name)
    branch = where(repository_id: repo_id, name: name || 'master').first_or_initialize
    branch.last_build = Build.where(repository_id: repo_id).last_on_branch(name)
    branch.save!
  end
end
