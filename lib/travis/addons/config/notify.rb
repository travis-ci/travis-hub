require 'travis/secure_config'
require 'travis/addons/helpers/hash'

module Travis
  module Addons
    class Config
      class Notify
        include Helpers::Hash

        DEFAULTS = {
          start:   { email: false,   webhooks: false,   campfire: false,   hipchat: false,   irc: false,   flowdock: false,   sqwiggle: false,   slack: false,   pushover: false   },
          success: { email: :change, webhooks: :always, campfire: :always, hipchat: :always, irc: :always, flowdock: :always, sqwiggle: :always, slack: :always, pushover: :always, billing: :always },
          failure: { email: :always, webhooks: :always, campfire: :always, hipchat: :always, irc: :always, flowdock: :always, sqwiggle: :always, slack: :always, pushover: :always },
          canceled:{ email: :always, webhooks: :always, campfire: :always, hipchat: :always, irc: :always, flowdock: :always, sqwiggle: :always, slack: :always, pushover: :always, billing: :always },
          errored: { email: :always, webhooks: :always, campfire: :always, hipchat: :always, irc: :always, flowdock: :always, sqwiggle: :always, slack: :always, pushover: :always }
        }

        attr_reader :build, :config

        def initialize(build, config)
          @build = build
          @config = deep_symbolize_keys(config)
        end

        def on?(type, event)
          send(:"on_#{event}_for?", type)
        end

        private

          FINISH_STATES = %i[passed failed errored canceled].freeze

          def on_started_for?(type)
            config = with_fallbacks(type, :on_start, DEFAULTS[:start][type])
            config == true || config == :always
          end

          def on_finished_for?(type)
            on_success_for?(type) || on_failure_for?(type)
          end

          def on_success_for?(type)
            !!if build_passed?
              config = with_fallbacks(type, :on_success, DEFAULTS[:success][type])
              config == :always || config == :change && (previous_build_failed? || initial_build?)
            end
          end

          def on_failure_for?(type)
            !!if build_failed?
              config = with_fallbacks(type, :on_failure, DEFAULTS[:failure][type])
              config == :always || config == :change && (previous_build_passed? || initial_build?)
            end
          end

          def on_canceled_for?(type)
            !!if build_canceled?
              config = with_fallbacks(type, :on_cancel, DEFAULTS[:canceled][type])
              config == :always || config == :change && (previous_build_passed? || initial_build?)
            end
          end

          def on_errored_for?(type)
            !!if build_errored?
              config = with_fallbacks(type, :on_error, DEFAULTS[:errored][type])
              config == :always || config == :change && (previous_build_passed? || initial_build?)
            end
          end

          def initial_build?
            blank?(build.previous_state)
          end

          def build_passed?
            build.state.try(:to_sym) == :passed
          end

          def build_canceled?
            build.state.try(:to_sym) == :canceled
          end

          def build_failed?
            !build_passed? && all_jobs_finished?
          end

          def previous_build_passed?
            build.previous_state.try(:to_sym) == :passed
          end

          def previous_build_failed?
            !previous_build_passed?
          end

          def all_jobs_finished?
            build.jobs.all? { |job| FINISH_STATES.include?(job.state) }
          end

          # Based on the given config (.travis.yml) we
          #
          # * first check for the given notification type (e.g. { notifications: { email: :on_success } })
          # * then check for global notification config (e.g. { notifications: :on_success })
          # * then fall back to the given default
          def with_fallbacks(type, key, default)
            result = if (config[type] && config[type].is_a?(Hash) && config[type].has_key?(key))
              config[type][key]
            elsif config.has_key?(key)
              config[key]
            else
              default
            end
            result.try(:to_sym)
          end

          def blank?(object)
            object.is_a?(NilClass) ? true : object.empty?
          end
      end
    end
  end
end
