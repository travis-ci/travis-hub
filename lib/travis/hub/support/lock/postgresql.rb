# http://hashrocket.com/blog/posts/advisory-locks-in-postgres
# https://github.com/mceachen/with_advisory_lock
# 13.3.4. Advisory Locks : http://www.postgresql.org/docs/9.3/static/explicit-locking.html
# http://www.postgresql.org/docs/9.3/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS

require 'zlib'
require 'timeout'

module Travis
  module Hub
    module Support
      module Lock
        class Postgresql < Struct.new(:name, :options)
          def exclusive
            Timeout.timeout(timeout) do
              sleep(rand(0.1..0.2)) until obtained?
              yield
            end
          ensure
            release unless transactional?
          end

          private

            def obtained?
              raise 'lock name cannot be blank' if name.nil? || name.empty?
              name   = "pg_try_advisory#{'_xact' if transactional?}_lock"
              result = connection.select_value("select #{name}(#{key});")
              result == 't' || result == 'true'
            end

            def release
              connection.execute("select pg_advisory_unlock(#{key});")
            end

            def timeout
              options[:timeout] || 30
            end

            def transactional?
              !!options[:transactional]
            end

            def connection
              ActiveRecord::Base.connection
            end

            def key
              Zlib.crc32(name)
            end
        end
      end
    end
  end
end
