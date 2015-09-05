require 'simple_states'
require 'core_ext/hash/deep_symbolize_keys'
require 'travis/event'
require 'travis/hub/model/job'
require 'travis/hub/model/build/denormalize'
require 'travis/hub/model/build/matrix'
require 'travis/hub/model/build/normalize'

class Build < ActiveRecord::Base
  include Denormalize, Normalize, SimpleStates, Travis::Event

  belongs_to :repository
  has_many   :jobs, -> { order(:id) }, as: :source

  class << self
    def last_on_branch(branch)
      pushes.where('branch IN (?)', branch).order('id DESC').first
    end

    def pushes
      where(event_type: 'push')
    end
  end

  states :created, :started, :passed, :failed, :errored, :canceled, ordered: true

  event  :start,   to: :started
  event  :finish,  to: :finished, if: :finish?
  event  :cancel,  to: :canceled, if: :finish?
  event  :reset,   to: :created,  if: :reset?
  event  :all, after: [:denormalize, :notify]

  serialize :config

  def start(data = {})
    self.attributes = { started_at: data[:started_at] }
  end

  def finish?
    !finished? && matrix.finished?
  end

  def finish(data = {})
    self.attributes = { state: matrix.state, duration: matrix.duration, finished_at: data[:finished_at] }
  end

  def finished?
    [:passed, :failed, :errored, :canceled].include?(state)
  end

  def reset?
    finished? && config_valid?
  end

  def reset(*)
    self.attributes = { state: :created, duration: nil, started_at: nil, finished_at: nil }
  end

  def cancel(*)
    self.attributes = { state: matrix.state, duration: matrix.duration, canceled_at: Time.now, finished_at: Time.now }
  end

  def config_valid?
    config[:'.result'] != 'parse_error'
  end

  def notify(event, *args)
    event = :create if event == :reset # TODO move to clients?
    super
  end

  def matrix
    Matrix.new(jobs, config[:matrix])
  end
end
