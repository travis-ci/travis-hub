class Stage < ActiveRecord::Base
  belongs_to :build
  has_many :jobs

  def finished?
    jobs.all?(&:finished?)
  end

  # TODO what's a better name for `failed || errored || canceled`, i.e. `not passed`?
  def failed?
    finished? && !jobs.all?(&:passed?)
  end

  def state
    if jobs.any?(&:canceled?)
      :canceled
    elsif jobs.any?(&:errored?)
      :errored
    elsif jobs.any?(&:failed?)
      :failed
    else
      :passed
    end
  end
end
