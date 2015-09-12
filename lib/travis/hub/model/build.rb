require 'simple_states'
require 'core_ext/hash/deep_symbolize_keys'
require 'travis/event'
require 'travis/hub/model/job'
require 'travis/hub/model/build/denormalize'
require 'travis/hub/model/build/matrix'

class Build < ActiveRecord::Base
  include Denormalize, SimpleStates, Travis::Event

  belongs_to :repository
  has_many   :jobs, -> { order(:id) }, as: :source

  states :created, :started, :passed, :failed, :errored, :canceled, ordered: true

  event  :start,   to: :started,  if: :start?
  event  :finish,  to: :finished, if: :finish?
  event  :cancel,  to: :canceled, if: :finish?
  event  :restart, to: :created,  if: :restart?
  event  :all, after: [:denormalize, :notify]

  serialize :config

  def config
    super || {}
  end

  def start?
    !started?
  end

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

  def restart?
    finished? && config_valid?
  end

  def restart(*)
    self.attributes = { state: :created, duration: nil, started_at: nil, finished_at: nil }
  end

  def cancel(*)
    self.attributes = { state: matrix.state, duration: matrix.duration, canceled_at: Time.now, finished_at: Time.now }
  end

  def config_valid?
    !config[:'.result'].to_s.include?('error')
  end

  def notify(event, *args)
    event = :create if event == :restart # TODO move to clients?
    super
  end

  def matrix
    Matrix.new(jobs, config[:matrix])
  end
end
