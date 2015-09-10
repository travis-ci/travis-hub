require 'travis/hub/model/build'
require 'travis/hub/model/log'
require 'travis/hub/model/repository'
require 'travis/hub/model/job/normalize'

class Job < ActiveRecord::Base
  include Normalize, SimpleStates, Travis::Event

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
  event :reset,   after: :propagate, if: :reset?
  event :all, after: :notify

  def duration
    started_at && finished_at ? finished_at - started_at : nil
  end

  def receive(data)
    self.received_at = data[:received_at]
  end

  def start(data)
    self.started_at = data[:started_at]
  end

  def finished?
    [:passed, :failed, :errored, :canceled].include?(state)
  end

  def finish(data)
    self.finished_at = data[:finished_at]
  end

  def reset?
    finished? && !invalid_config?
  end

  def reset(*)
    self.attributes = { state: :created, queued_at: nil, received_at: nil, started_at: nil, finished_at: nil }
    log ? log.clear! : build_log
  end

  def cancel?
    !finished?
  end

  def cancel(*)
    self.attributes = { canceled_at: Time.now, finished_at: Time.now }
  end

  def invalid_config?
    config[:'.result'] == 'parse_error'
  end

  def notify(event, *args)
    event = :create if event == :reset # TODO move to clients?
    super
  end

  def propagate(event, *args)
    build.send(:"#{event}!", *args)
    true
  end
end
