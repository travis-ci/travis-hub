require 'simple_states'
require 'travis/event'
require 'travis/hub/model/job'
require 'travis/hub/model/build/denormalize'
require 'travis/hub/model/build/matrix'

class Build < ActiveRecord::Base
  include Denormalize, SimpleStates, Travis::Event

  FINISHED_STATES = [:passed, :failed, :errored, :canceled]

  belongs_to :repository
  has_many   :jobs, -> { order(:id) }, as: :source

  event  :start,   if: :start?
  event  :finish,  if: :finish?, to: FINISHED_STATES
  event  :cancel,  if: :cancel?
  event  :restart, if: :restart?
  event  :all, after: [:denormalize, :notify]

  serialize :config

  def config
    super || {}
  end

  def start?(*)
    !started?
  end

  def started_at
    started_at = jobs.first.started_at
  end

  def finish?(*)
    matrix.finished?
  end

  def finish(*)
    self.attributes = { state: matrix.state, duration: matrix.duration }
  end

  def finished?
    FINISHED_STATES.include?(state)
  end

  def restart?(*)
    config_valid?
  end

  def restart(*)
    reset_state
  end

  def cancel?(*)
    !finished? && finish?
  end

  def cancel(*)
    self.finished_at = Time.now
  end

  private

    def matrix
      Matrix.new(jobs, config[:matrix])
    end

    def config_valid?
      not config[:'.result'].to_s.include?('error')
    end
end
