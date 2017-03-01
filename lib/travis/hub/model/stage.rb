class Stage < ActiveRecord::Base
  belongs_to :build
  has_many :jobs

  def finish!(*)
    return unless failed?
    cancel_pending_jobs
    build.finish!(state: state)
  end

  def finished?
    jobs.all?(&:finished?)
  end

  # What's a better name for `[failed|errored|canceled]`
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

  private

    def cancel_pending_jobs
      # This would cancel the build several times, because `build.finish?` only
      # rejects based on `canceled?` which is because of the way how we error
      # builds in Gatekeeper (and a race'ish condition between Gatekeeper and
      # Hub, see https://github.com/travis-pro/team-teal/issues/1167 and
      # https://github.com/travis-pro/team-teal/issues/1247)
      # jobs.pending.each(&:cancel!)

      to_cancel = build.jobs.pending
      attrs = { state: :canceled, finished_at: Time.now }

      # If we notify early then Scheduler might receive an event and queue jobs
      # that are supposed to be canceled. (Hub could then tell the workers to
      # also cancel them, but it seems better to not notify Scheduler early.)
      # It would be nice to change Hub's design so that we collect notifications
      # and send them only after all DB state has been updated properly.
      to_cancel.each { |job| job.update_attributes!(attrs) }
      to_cancel.each { |job| job.notify(:finish) }
    end
end
