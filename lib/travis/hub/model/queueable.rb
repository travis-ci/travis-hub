class Queueable < ActiveRecord::Base
  self.table_name = :queueable_jobs
end
