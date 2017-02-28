require 'simple_states'
require 'travis/event'
require 'travis/hub/model/job'
require 'travis/hub/model/build/denormalize'
require 'travis/hub/model/build/matrix'
require 'travis/hub/update_current_build'

class Build < ActiveRecord::Base
  include Denormalize, SimpleStates, Travis::Event

  FINISHED_STATES = [:passed, :failed, :errored, :canceled]

  belongs_to :repository
  has_many   :jobs, -> { order(:id) }, as: :source
  has_many   :stages, -> { order(:id) }

  event  :start,   if: :start?
  event  :finish,  if: :finish?, to: FINISHED_STATES
  event  :cancel,  if: :cancel?
  event  :restart, if: :restart?
  event  :all, after: [:denormalize, :notify]

  serialize :config

  def pull_request?
    event_type == 'pull_request'
  end

  def config
    super || {}
  end

  def start?(*)
    !started?
  end

  def start(*)
    Travis::Hub::UpdateCurrentBuild.new(self).update!
  end

  def finish?(*)
    !canceled? && (matrix.finished? || stage && stage.failed?)
  end

  def finish(*)
    if stage && stage.failed?
      # TODO make Stage a state machine? move the following to the stage model,
      # and call it from the job? might be simpler.
      update_attributes!(state: stage.state, duration: matrix.duration)

      # this would run into an endless loop, because `finish?` only rejects
      # based on `canceled?` which is because of the way how we error builds in
      # Gatekeeper (and a race condition between Gatekeeper and Hub, see
      # https://github.com/travis-pro/team-teal/issues/1167 and
      # https://github.com/travis-pro/team-teal/issues/1247)
      # jobs.pending.each(&:cancel!)

      to_cancel = jobs.pending
      attrs = { state: :canceled, finished_at: Time.now }

      # if we notify early then Scheduler might receive an event and queue jobs
      # that are supposed to be canceled. Hub could then tell the workers to
      # also cancel them, but it seems better to not notify Scheduler early.
      # it would be nice to change Hub's design so that we'd collect
      # notifications and send them only after all DB state has been updated
      # properly.
      to_cancel.each { |job| job.update_attributes!(attrs) }
      to_cancel.each { |job| job.notify(:finish) }
    else
      update_attributes!(state: matrix.state, duration: matrix.duration)
    end
  end

  def finished?
    FINISHED_STATES.include?(state)
  end

  def restart?(*)
    config_valid?
  end

  def restart(*)
    %w(duration started_at finished_at canceled_at).each { |attr| write_attribute(attr, nil) }
    self.state = :created
  end

  def cancel?(*)
    !finished? && finish?
  end

  def cancel(*)
    self.duration    = matrix.duration
    self.finished_at = Time.now
  end

  private

    def matrix
      Matrix.new(jobs, config[:matrix])
    end

    def config_valid?
      not config[:'.result'].to_s.include?('error')
    end

    def stage
      return instance_variable_get(:@state) if instance_variable_defined?(:@state)
      @state = jobs.map(&:stage).compact.detect(&:failed?)
    end
end
