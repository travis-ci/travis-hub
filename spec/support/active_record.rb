require_relative 'environment'

require 'active_record'
require 'logger'
require 'fileutils'
require 'database_cleaner'

FileUtils.mkdir_p('log')

# TODO: why not make this use Travis::Database.connect ?
config = Travis.config.database.dup
config.merge!('adapter' => 'jdbcpostgresql', 'username' => ENV['USER']) if RUBY_PLATFORM == 'java'

ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.logger = Logger.new('log/test.db.log')
ActiveRecord::Base.configurations = { 'test' => config }
ActiveRecord::Base.establish_connection('test')

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

module Support
  module ActiveRecord
    extend ActiveSupport::Concern

    included do
      before :each do
        DatabaseCleaner.start
      end

      after :each do
        DatabaseCleaner.clean
      end
    end
  end
end
