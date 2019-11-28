require 'date'
require 'json'
require 'travis/instrumentation'
require 'travis/hub/helper/context'
require 'travis/hub/model/job'

module Travis
  module Hub
    module Service
      class UpdateDeploy < Struct.new(:event, :data)
        include Helper::Context
        extend Instrumentation

        module Dpl
          def self.providers
            @providers || Providers.new
          end

          class Provider
            attr_reader :data

            def initialize(data)
              @data = data.map { |key, value| [key.to_sym, value] }.to_h
            end

            def name
              [data[:name], data[:strategy]].compact.join(':')
            end

            def status?
              %w(dev alpha beta).include?(data[:status])
            end

            def update_status?
              status? && (Date.today - 30 > Date.parse(data[:date]))
            end
          end

          class Providers
            def [](name)
              objs[name]
            end

            def objs
              @objs ||= load.map { |obj| [obj.name, obj] }.to_h
            end

            def load
              JSON.parse(File.read('dpl.json')).map { |data| Provider.new(data) }
            end
          end
        end

        MSG = 'dpl `%{name}` has been in %{status} since %{date}, and can be updated (%{url})'

        STRATEGY = {
          heroku: :api,
          pages: :git
        }

        def run
          notify_slack if notify_slack?
        end
        instrument :run

        def job
          @job ||= Job.find(job_id)
        end

        def data
          @data ||= super.tap do |data|
            data[:strategy] ||= STRATEGY[data[:provider]&.to_sym]
          end
        end

        private

          def notify_slack?
            success? && edge? && provider&.update_status? && slug != 'travis-ci/dpl'
          end

          def notify_slack
            Faraday.post(slack_url, JSON.dump(text: msg)) if slack_url
          end

          def msg
            MSG % provider.data.merge(url: job_url)
          end

          def job_url
            [config.host, job.repository.slug, 'jobs', job_id].join('/')
          end

          def job_id
            data[:job_id]
          end

          def slug
            job.repository.slug
          end

          def provider
            @provider ||= Dpl.providers[provider_name].tap do |provider|
              error "Unable to find provider #{provider_name}" if provider.nil?
            end
          end

          def provider_name(strategy = data[:strategy])
            [data[:provider], strategy].compact.join(':')
          end

          def success?
            data[:status] == '0'
          end

          def edge?
            return unless edge = data[:edge]
            return edge.is_a?(TrueClass) unless edge.is_a?(Hash)
            !edge.key?(:repo) || edge[:repo] == 'travis-ci/dpl'
          end

          def config
            Hub.context.config
          end

          def slack_url
            ENV['SLACK_DPL_LOGS_URL']
          end

          class Instrument < Instrumentation::Instrument
            def run_received
              publish msg: "event: #{target.event} for repo=#{target.job.repository.slug} #{to_pairs(target.data)}"
            end

            def run_completed
              publish msg: "event: #{target.event} for repo=#{target.job.repository.slug} #{to_pairs(target.data)}"
            end
          end
          Instrument.attach_to(self)
        end
    end
  end
end
