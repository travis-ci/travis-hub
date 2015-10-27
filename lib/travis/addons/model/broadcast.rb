class Broadcast < ActiveRecord::Base
  class << self
    def by_repo(repository)
      sql = %(
        recipient_type IS NULL OR
        recipient_type = ? AND recipient_id = ? OR
        recipient_type = ? AND recipient_id = ?
      )
      active.where(sql, 'Repository', repository.id, repository.owner_type, repository.owner_id)
    end

    def active
      where('created_at >= ? AND (expired IS NULL OR expired <> ?)', 14.days.ago, true).order('id DESC')
    end
  end
end
