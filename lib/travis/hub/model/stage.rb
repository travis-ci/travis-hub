require 'simple_states'
require 'travis/event'
require 'travis/hub/model/build/matrix'

class Stage < ActiveRecord::Base
  include SimpleStates

  event :start,  if: :start?
  event :finish, if: :finish?, to: Build::FINISHED_STATES
  event :cancel, if: :finish?
  event :restart
  event :reset
  event :all, after: :propagate

  belongs_to :build
  has_many :jobs

  def start?(*)
    !started?
  end

  def finish?(*)
    matrix.finished?
  end

  def finish(*)
    update_attributes!(state: matrix.state)
    cancel_pending_jobs unless passed?
  end

  def finished?
    FINISHED_STATES.include?(state)
  end

  def cancel(*)
    self.finished_at = Time.now
  end

  def restart(*)
    clear
  end

  def reset(*)
    clear
  end

  private

    def matrix
      @matrix ||= Build::Matrix.new(jobs, build.config[:matrix])
    end

    def clear
      %w(started_at finished_at).each { |attr| write_attribute(attr, nil) }
      self.state = :created
    end

    def cancel_pending_jobs
      # This would cancel the build several times, because `build.finish?` only
      # rejects based on `canceled?` which is because of the way how we error
      # builds in Gatekeeper (and a race'ish condition between Gatekeeper and
      # Hub, see https://github.com/travis-pro/team-teal/issues/1167 and
      # https://github.com/travis-pro/team-teal/issues/1247)
      # jobs.pending.each(&:cancel!)

      to_cancel = build.jobs.pending - jobs
      attrs = { state: :canceled, finished_at: Time.now }

      # If we notify early then Scheduler might receive an event and queue jobs
      # that are supposed to be canceled. (Hub could then tell the workers to
      # also cancel them, but it seems better to not notify Scheduler early.)
      # It would be nice to change Hub's design so that we collect notifications
      # and send them only after all DB state has been updated properly.
      to_cancel.each { |job| job.update_attributes!(attrs) }
      to_cancel.each { |job| job.notify(:finish) }

      stages = Stage.where(id: to_cancel.map(&:stage_id))
      stages.each { |stage| stage.update_attributes!(attrs) }
    end

    def propagate(event, *args)
      build.send(:"#{event}!", *args)
    end
end
