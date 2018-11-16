module Travis
  module Hub
    module Service
      class StateUpdate < Struct.new(:event, :data, :block)
        class Counter < Struct.new(:job_id, :redis)
          TTL = 3600 * 24

          def count
            @count ||= redis.get(key).to_i
          end

          def store(count)
            redis.setex(key, TTL, count)
          end

          private

            def key
              "job:state_update_count:#{job_id}"
            end
        end

        include Helper::Context

        OUT_OF_BAND = [:cancel, :restart]

        MSGS = {
          missing:   'Received state update (%p) with no count for job id=%p, last known count: %p.',
          ordered:   'Received state update %p (%p) for job id=%p, last known count: %p',
          unordered: 'Received state update %p (%p) for job id=%p, last known count: %p. Skipping the message.',
        }

        def apply
          if !enabled? || out_of_band?
            call
          elsif missing?
            missing
          elsif ordered?
            ordered
          else
            unordered
          end
        end

        private

          def call
            block.call
          end

          def enabled?
            ENV['UPDATE_COUNT'] == 'true'
          end

          def out_of_band?
            OUT_OF_BAND.include?(event)
          end

          def missing?
            count.nil?
          end

          def missing
            warn :missing, event, job_id, counter.count
            call
            store
          end

          def ordered
            info :ordered, count, event, job_id, counter.count
            call
            store
          end

          def unordered
            warn :unordered, count, event, job_id, counter.count
          end

          def ordered?
            count >= counter.count
          end

          def store
            counter.store(count)
          end

          def counter
            @counter ||= Counter.new(job_id, redis)
          end

          def job_id
            data[:id]
          end

          def count
            meta[:state_update_count]
          end

          def meta
            data[:meta] || {}
          end
      end
    end
  end
end
