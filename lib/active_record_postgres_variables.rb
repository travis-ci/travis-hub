# This backports support for the :variables option on postgres database details from ActiveRecord 4 to ActiveRecord 3.
require 'active_record'

if ActiveRecord::VERSION::MAJOR < 4
  require 'active_record/connection_adapters/postgresql_adapter'

  class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    alias_method :old_configure_connection, :configure_connection unless method_defined?(:old_configure_connection)

    def configure_connection
      result = old_configure_connection
      set_variables
      result
    end

    def set_variables
      return unless variables = @config[:variables]

      # copied from AR 4.2.1
      variables.map do |k, v|
        if v == ':default' || v == :default
          # Sets the value to the global or compile default
          execute("SET SESSION #{k} TO DEFAULT", 'SCHEMA')
        elsif !v.nil?
          execute("SET SESSION #{k} TO #{quote(v)}", 'SCHEMA')
        end
      end
    end
  end
end
