class Log < ActiveRecord::Base
  class Part < ActiveRecord::Base
    self.table_name = 'log_parts'
  end

  has_many :parts, class_name: 'Log::Part', foreign_key: :log_id

  def clear!
    update_column(:content, '')        # TODO why in the world does update_attributes not set content to ''
    update_column(:aggregated_at, nil) # TODO why in the world does update_attributes not set aggregated_at to nil?
    update_column(:archived_at, nil)
    update_column(:archive_verified, nil)
    parts.delete_all
  end
end
