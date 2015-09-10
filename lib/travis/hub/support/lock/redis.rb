require 'monitor'
begin
  require 'redlock'
rescue LoadError
end

module Travis
  module Support
    module Lock
      class Redis < Struct.new(:name, :options)
        class LockError < StandardError
          def initialize(key)
            super("Could not obtain lock for #{key.inspect} on Redis.")
          end
        end

        extend MonitorMixin

        TTL     = 5 * 60
        RETRIES = 5
        SLEEP   = 0.1

        def self.client
          synchronize do
            @client ||= Redlock::Client.new([Travis::Hub.config[:redis][:url]])
          end
        end

        attr_reader :retries

        def exclusive
          retrying do
            client.lock(key, TTL) do |lock|
              lock ? yield : raise(LockError.new(key))
            end
          end
        end

        private

          def client
            self.class.client
          end

          def retries
            @retries ||= 0
          end

          def key
            name
          end

          def retrying
            yield
          rescue LockError
            raise if retries.to_i >= RETRIES
            sleep SLEEP
            @retries = retries + 1
            retry
          end
      end
    end
  end
end
