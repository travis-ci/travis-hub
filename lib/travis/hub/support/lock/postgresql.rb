# http://hashrocket.com/blog/posts/advisory-locks-in-postgres
# https://github.com/mceachen/with_advisory_lock
# 13.3.4. Advisory Locks : http://www.postgresql.org/docs/9.3/static/explicit-locking.html
# http://www.postgresql.org/docs/9.3/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS

require 'zlib'
require 'active_record'

module Travis
  module Support
    module Lock
      class Postgresql < Struct.new(:name, :options)
        WAIT = 0.0001..0.0009

        attr_reader :lock

        def exclusive(&block)
          with_lock do
            transactional? ? connection.transaction(&block) : yield
          end
          # TODO how to deal with timeout when using try?
        end

        private

          def with_lock
            wait until obtained? || timeout?
            puts "Done waiting. Lock: #{lock.inspect}"
            return unless lock
            yield
          ensure
            release unless transactional?
          end

          def obtained?
            raise 'lock name cannot be blank' if name.nil? || name.empty?
            with_statement_timeout do
              result = connection.select_value("select #{pg_function}(#{key});")
              @lock  = try? ? result == 't' || result == 'true' : true
            end
          end

          def release
            connection.execute("select pg_advisory_unlock(#{key});")
          end

          def wait
            sleep(rand(WAIT)) if try?
          end

          def started
            @started ||= Time.now
          end

          def timeout?
            started + timeout < Time.now
          end

          def timeout
            options[:timeout] || 30
          end

          def try?
            !!options[:try]
          end

          def transactional?
            !!options[:transactional]
          end

          def with_statement_timeout
            connection.select_value("set statement_timeout to #{timeout * 1000};") unless try?
            yield
          rescue ActiveRecord::StatementInvalid => e
            retry if defined?(PG) && e.original_exception.is_a?(PG::QueryCanceled)
            raise
          end

          def pg_function
            func = ['pg', 'advisory', 'lock']
            func.insert(2, 'xact') if transactional?
            func.insert(1, 'try')  if try?
            func.join('_')
          end

          def connection
            ActiveRecord::Base.connection
          end

          def key
            Zlib.crc32(name).to_i & 0x7fffffff
          end
      end
    end
  end
end
