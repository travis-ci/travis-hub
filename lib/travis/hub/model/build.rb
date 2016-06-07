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

  event  :start,   if: :start?
  event  :finish,  if: :finish?, to: FINISHED_STATES
  event  :cancel,  if: :cancel?  #TODO check if this is ever used?
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
    matrix.finished? && !canceled?
  end

  def finish(*)
    self.attributes = { state: matrix.state, duration: matrix.duration }
  end

  def finished?
    FINISHED_STATES.include?(state)
  end

  # Conditions on restart? method were added to match current tests, because the `created` state
  # is now forced to be set on a restart event
  # eg. https://github.com/travis-ci/travis-hub/blob/master/spec/travis/hub/model/build_spec.rb#L180
  def restart?(*)
    (queued? || finished? || started? || matrix.created?) && config_valid?
  end

  def restart(*)
    %w(duration started_at finished_at).each { |attr| write_attribute(attr, nil) }
    self.state = :created
  end

  def cancel?(*)
    !finished? && finish?
  end

  def cancel(*)
    self.finished_at = Time.now
  end

  def queued?
    self.state.to_s == 'queued'
  end

  private

    def matrix
      Matrix.new(jobs, config[:matrix])
    end

    def config_valid?
      not config[:'.result'].to_s.include?('error')
    end
end
