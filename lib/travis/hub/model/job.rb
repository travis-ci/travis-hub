require 'simple_states'
require 'travis/event'
require 'travis/hub/model/build'
require 'travis/hub/model/repository'

class JobConfig < ActiveRecord::Base
end

class JobVersion < ActiveRecord::Base
  belongs_to :job
end

class Job < ActiveRecord::Base
  include SimpleStates, Travis::Event

  FINISHED_STATES = [:passed, :failed, :errored, :canceled]

  Job.inheritance_column = :unused

  belongs_to :repository
  belongs_to :owner, polymorphic: true
  belongs_to :build, polymorphic: true, foreign_key: :source_id, foreign_type: :source_type
  belongs_to :commit
  belongs_to :stage
  belongs_to :config, foreign_key: :config_id, class_name: JobConfig
  has_many   :versions, class_name: JobVersion
  has_one    :queueable

  self.initial_state = :persisted # TODO go away once there's `queueable`

  event :create,  after: :propagate
  event :receive
  event :start,   after: :propagate
  event :finish,  after: :propagate, to: FINISHED_STATES
  event :cancel,  after: :propagate, if: :cancel?
  event :restart, after: :propagate
  event :reset,   after: :propagate
  event :all, after: :notify

  serialize :config

  class << self
    def pending
      where('state NOT IN (?)', FINISHED_STATES)
    end
  end

  def config
    config = super&.config || has_attribute?(:config) && read_attribute(:config) || {}
    config.deep_symbolize_keys! if config.respond_to?(:deep_symbolize_keys!)
  end

  def received_at=(*)
    super
    ensure_positive_queue_time
  end

  def duration
    finished_at - started_at if started_at && finished_at
  end

  def finished?
    FINISHED_STATES.include?(state.try(:to_sym))
  end

  def create
    set_queueable
  end

  def restart(*)
    create_version
    clear
    self.restarted_at = Time.now
  end

  def reset(*)
    clear
  end

  def cancel?(*)
    !finished?
  end

  def cancel(msg)
    self.finished_at = Time.now
    unset_queueable
  end

  def notify(event, *args)
    event = :restart if event == :reset
    super
  end

  private

    CLEAR_ATTRS   = %w(queued_at received_at started_at finished_at canceled_at)
    VERSION_ATTRS = %w(created_at queued_at received_at started_at finished_at restarted_at)

    def create_version
      attrs = attributes.slice(*VERSION_ATTRS)
      attrs = attrs.merge(number: next_version_number, state: state_was, restarted_at: restarted_at_was)
      versions.create!(attrs)
    end

    def next_version_number
      versions.maximum(:number).try(:+, 1) || 1
    end

    def clear
      self.state = :created
      clear_attrs
      clear_log
      save!
      set_queueable
    end

    def clear_attrs
      CLEAR_ATTRS.each { |attr| write_attribute(attr, nil) }
    end

    def clear_log
      logs_api.update(id, '', clear: true)
    end

    def set_queueable
      queueable || create_queueable
    end

    def unset_queueable
      Queueable.where(job_id: id).delete_all
    end

    def ensure_positive_queue_time
      # TODO should ideally sit on Handler, but Worker does not yet include `queued_at`
      return unless queued_at && received_at && queued_at > received_at
      self.received_at = queued_at
    end

    def propagate(event, *args)
      target = stage && stage.respond_to?(:"#{event}!") ? stage : build
      target.send(:"#{event}!", *args)
    end

    def logs_api
      @logs_api ||= Travis::Hub::Support::Logs.new(
        Travis::Hub.context.config.logs_api
      )
    end
end
