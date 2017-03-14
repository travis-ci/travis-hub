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
            build.jobs.each do |job|
              auto_cancel(job) if event == :cancel && auto_cancel?
              job.reload.send(:"#{event}!", attrs)
            end
          end

          def auto_cancel?
            !!meta[:auto]
          end

          def auto_cancel(job)
            metrics.meter('hub.job.auto_cancel')
            job.log.canceled(meta)
          rescue ActiveRecord::StatementInvalid => e
            logger.warn "[cancel] failed to update the log due to a db exception: #{e.message}."
          end

          def meta
            @meta ||= (data[:meta] || {}).symbolize_keys
          end

          def attrs
            data.reject { |key, _| key == :id || key == :meta }
          end

          def notify
            build.jobs.each { |job| NotifyWorkers.new(context).cancel(job) } if event == :cancel
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
