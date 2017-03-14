class Log < ActiveRecord::Base
  class Part < ActiveRecord::Base
    self.table_name = 'log_parts'
  end

  has_many :parts, class_name: 'Log::Part', foreign_key: :log_id

  def clear
    update_column(:content, '')        # TODO why in the world does update_attributes not set content to ''
    update_column(:aggregated_at, nil) # TODO why in the world does update_attributes not set aggregated_at to nil?
    update_column(:archived_at, nil)
    update_column(:archive_verified, nil)
    update_column(:removed_at, nil)
    update_column(:removed_by, nil)
    Part.where(log_id: id).delete_all
  end

  MSGS = {
    canceled:     %(This job was cancelled because the "Auto Cancellation" feature is currently enabled, and a more recent build (#%{number}) for %{info} came in while this job was waiting to be processed.\n\n),
    push:         'branch %{branch}',
    pull_request: 'pull request #%{pull_request_number}',
  }

  # TODO message logs instead
  def canceled(data)
    event, number = data[:event].to_sym, data[:number]
    line = MSGS[:canceled] % { number: number, info: MSGS[event] % { branch: data[:branch], pull_request_number: data[:pull_request_number] } }
    number = parts.last.try(:number).to_i + 1
    Part.create(log_id: id, content: line, number: number, final: true)
  end
end
