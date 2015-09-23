require 'simple_states'
require 'travis/event'
require 'travis/hub/model/job'
require 'travis/hub/model/build/denormalize'
require 'travis/hub/model/build/matrix'

class Build < ActiveRecord::Base
  include Denormalize, SimpleStates, Travis::Event

  belongs_to :repository
  has_many   :jobs, -> { order(:id) }, as: :source

  states :created, :started, :passed, :failed, :errored, :canceled, ordered: true

  event  :start,   if: :start?
  event  :finish,  if: :finish?
  event  :cancel,  if: :cancel?
  event  :restart, if: :restart?
  event  :all, after: [:denormalize, :notify]

  serialize :config

  def config
    super || {}
  end

  def start?
    !started?
  end

  def finish?(event, data = {})
    !finished? && matrix.finished?
  end

  def finish(data = {})
    self.attributes = { state: matrix.state, duration: matrix.duration }
  end

  def finished?
    [:passed, :failed, :errored, :canceled].include?(state)
  end

  def restart?
    finished? && config_valid?
  end

  def restart(*)
    reset_state
  end

  alias cancel? finish?

  def cancel(options = {})
    self.finished_at = Time.now
  end

  private

    def config_valid?
      not config[:'.result'].to_s.include?('error')
    end

    def matrix
      @matrix ||= Matrix.new(jobs, config[:matrix])
    end
end
