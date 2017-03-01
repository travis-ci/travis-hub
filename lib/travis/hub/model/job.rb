require 'simple_states'
require 'travis/event'
require 'travis/hub/model/build'
require 'travis/hub/model/log'
require 'travis/hub/model/repository'

class Job < ActiveRecord::Base
  include SimpleStates, Travis::Event

  FINISHED_STATES = [:passed, :failed, :errored, :canceled]

  Job.inheritance_column = :unused

  belongs_to :repository
  belongs_to :owner, polymorphic: true
  belongs_to :build, polymorphic: true, foreign_key: :source_id, foreign_type: :source_type
  belongs_to :commit
  belongs_to :stage
  has_one    :log

  event :receive
  event :start,   after: :propagate
  event :finish,  after: :propagate, to: FINISHED_STATES
  event :cancel,  after: :propagate, if: :cancel?
  event :restart, after: :propagate, if: :restart?
  event :all, after: :notify

  serialize :config

  class << self
    def pending
      where('state NOT IN (?)', FINISHED_STATES)
    end
  end

  def config
    super || {}
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

  def restart?(*)
    config_valid?
  end

  def restart(*)
    self.state = :created
    clear_attrs %w(started_at queued_at finished_at worker canceled_at)
    clear_log
  end

  def reset!(*)
    restart
    save!
  end

  def cancel?(*)
    !finished?
  end

  def cancel(msg)
    self.finished_at = Time.now
  end

  private

    def ensure_positive_queue_time
      # TODO should ideally sit on Handler, but Worker does not yet include `queued_at`
      return unless queued_at && received_at && queued_at > received_at
      self.received_at = queued_at
    end

    def clear_attrs(attrs)
      attrs.each { |attr| write_attribute(attr, nil) }
    end

    def clear_log
      return clear_log_via_http if logs_api_enabled?
      log ? log.clear : build_log
    end

    def propagate(event, *args)
      build.send(:"#{event}!", *args)
      stage.send(:finish!) if stage && event == :finish
    end

    def config_valid?
      !config[:'.result'].to_s.include?('error')
    end

    def clear_log_via_http
      logs_api.update(id, '', clear: true)
    end

    def logs_api_enabled?
      Travis::Hub.context.config.logs_api.enabled?
    end

    def logs_api
      @logs_api ||= Travis::Hub::Support::Logs.new(
        Travis::Hub.context.config.logs_api
      )
    end
end
