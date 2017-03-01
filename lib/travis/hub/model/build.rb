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
  belongs_to :owner, polymorphic: true
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
    !canceled? && matrix.finished?
  end

  def finish(_, attrs = {})
    update_attributes!(state: matrix_state, duration: matrix.duration)
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

    def matrix_state
      stage = stages.detect(&:failed?)
      stage ? stage.state : matrix.state
    end

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
