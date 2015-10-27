require 'travis/instrumentation'
require 'travis/hub/helper/context'
require 'travis/hub/helper/locking'
require 'travis/hub/model/build'
require 'travis/hub/service/notify_workers'

module Travis
  module Hub
    module Service
      class UpdateBuild < Struct.new(:event, :data)
        include Helper::Context, Helper::Locking
        extend Instrumentation

        EVENTS = [:start, :finish, :cancel, :restart]

        def run
          exclusive do
            validate
            update_jobs
            notify
          end
        end
        instrument :run

        def build
          @build ||= Build.find(data[:id])
        end

        private

          def update_jobs
            build.jobs.each { |job| job.reload.send(:"#{event}!", attrs) }
          end

          def attrs
            data.reject { |key, _| key == :id }
          end

          def notify
            build.jobs.each { |job| NotifyWorkers.new.cancel(job) } if event == :cancel
          end

          def validate
            EVENTS.include?(event) || unknown_event
          end

          def exclusive(&block)
            super("hub:build-#{build.id}", config.lock, &block)
          end

          def unknown_event
            fail ArgumentError, "Unknown event: #{event.inspect}, data: #{data}"
          end

          class Instrument < Instrumentation::Instrument
            def run_received
              publish msg: "event: #{target.event} for repo=#{target.build.repository.slug} #{to_pairs(target.data)}"
            end

            def run_completed
              publish msg: "event: #{target.event} for repo=#{target.build.repository.slug} #{to_pairs(target.data)}"
            end
          end
          Instrument.attach_to(self)
        end
    end
  end
end
