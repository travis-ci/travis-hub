require 'metriks'
require 'travis/support/instrumentation'
require 'travis/hub/helpers/locking'
require 'travis/hub/model/build'
require 'travis/hub/services/workers'
require 'travis/hub/support/lock'

module Travis
  module Hub
    module Services
      class UpdateBuild
        include Helpers::Locking
        extend Instrumentation

        EVENTS = [:cancel, :restart]

        attr_reader :event, :data

        def initialize(params)
          @event = params[:event].try(:to_sym)
          @data  = params[:data].symbolize_keys
        end

        def run
          validate
          update_build
          notify
        end
        instrument :run

        private

          def update_build
            exclusive "hub:update_build:#{data[:id]}" do
              build.send(:"#{event}!", data)
            end
          end

          def notify
            build.jobs.each { |job| Workers.new.cancel(job) } if build.canceled?
          end

          def build
            @build ||= Build.find(data[:id])
          end

          def validate
            EVENTS.include?(event) || unknown_event
          end

          def unknown_event
            fail ArgumentError, "Unknown event: #{event.inspect}, data: #{data}"
          end

          class Instrument < Instrumentation::Instrument
            def run_completed
              publish(
                msg: "event: #{target.event} for <Build id=#{target.data[:id]}> data=#{target.data.inspect}",
                build_id: target.data[:id],
                event: target.event,
                data: target.data
              )
            end
          end
          Instrument.attach_to(self)
        end
    end
  end
end
