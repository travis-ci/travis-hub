require 'travis/hub/model/build'
require 'travis/hub/model/log'
require 'travis/hub/model/repository'

class Job < ActiveRecord::Base
  include SimpleStates, Travis::Event

  Job.inheritance_column = :missing

  has_one    :log
  belongs_to :repository
  belongs_to :build, polymorphic: true, foreign_key: :source_id, foreign_type: :source_type
  belongs_to :commit

  serialize :config

  states :created, :queued, :received, :started, :passed, :failed, :errored, :canceled, ordered: true

  event :receive
  event :start,   after: :propagate
  event :finish,  after: :propagate
  event :cancel,  after: :propagate, if: :cancel?
  event :restart, after: :propagate, if: :restart?
  event :all, after: :notify

  def config
    super || {}
  end

  def duration
    finished_at - started_at if started_at && finished_at
  end

  def finished?
    [:passed, :failed, :errored, :canceled].include?(state)
  end

  def restart?
    finished? && !invalid_config?
  end

  def restart(*)
    reset_state
    log.clear
  end

  def cancel?
    !finished?
  end

  def cancel(*)
    self.finished_at = Time.now
  end

  def invalid_config?
    config[:'.result'] == 'parse_error'
  end

  def propagate(event, *args)
    build.send(:"#{event}!", *args)
  end
end
