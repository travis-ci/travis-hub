require 'simple_states'
require 'travis/event'
require 'travis/hub/model/job'
require 'travis/hub/model/build/denormalize'
require 'travis/hub/model/build/matrix'
require 'travis/hub/update_current_build'

SimpleStates.module_eval do
  def state=(state)
    state = state.to_sym unless state.nil?
    super(state)
  end
end

class BuildConfig < ActiveRecord::Base
end

class Build < ActiveRecord::Base
  include Denormalize, SimpleStates, Travis::Event

  FINISHED_STATES = [:passed, :failed, :errored, :canceled]

  belongs_to :repository
  belongs_to :owner, polymorphic: true
  belongs_to :config, foreign_key: :config_id, class_name: BuildConfig
  belongs_to :sender, polymorphic: true
  has_many   :jobs, -> { order(:id) }, as: :source
  has_many   :stages, -> { order(:id) }

  event :create
  event :start,   if: :start?
  event :finish,  if: :finish?, to: FINISHED_STATES
  event :cancel,  if: :cancel?
  event :restart, if: :restart?
  event :reset
  event :all, after: [:denormalize, :notify]

  serialize :config

  def pull_request?
    event_type == 'pull_request'
  end

  def config
    config = super&.config || has_attribute?(:config) && read_attribute(:config) || {}
    config.deep_symbolize_keys! if config.respond_to?(:deep_symbolize_keys!)
  end

  def start?(*)
    !started?
  end

  def start(*)
    Travis::Hub::UpdateCurrentBuild.new(self).update!
  end

  def finish?(*)
    !canceled? && matrix.finished?
  end

  def finish(*)
    update_attributes!(state: matrix_state, duration: matrix.duration)
  end

  def finished?
    FINISHED_STATES.include?(state)
  end

  def restart?(*)
    config_valid?
  end

  def restart(*)
    clear
    self.restarted_at = Time.now
  end

  def reset(*)
    clear
  end

  def cancel?(*)
    !finished? && finish?
  end

  def cancel(*)
    self.duration    = matrix.duration
    self.finished_at = Time.now
  end

  private

    def clear
      %w(duration started_at finished_at canceled_at).each { |attr| write_attribute(attr, nil) }
      self.state = :created
    end

    def matrix_state
      stage = stages.reject(&:passed?).first
      stage ? stage.state : matrix.state
    end

    def matrix
      # merging jobs and matrix can be removed once all configs go through travis-yml
      Matrix.new(jobs, config.values_at(:jobs, :matrix).select { |obj| obj.is_a?(Hash) }.inject(&:merge))
    end

    def config_valid?
      not config[:'.result'].to_s.include?('error')
    end
end
