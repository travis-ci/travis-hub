require 'travis/hub'
require 'time'

require 'database_cleaner'
require 'support/factories'
require 'support/logger'
require 'travis/hub/handler/metrics'

Travis::Addons.setup(encryption: { key: 'secret' * 10 })
Travis::Event.setup
Travis::Database.connect(Travis::Hub.config.database.to_h)
ActiveRecord::Base.logger = nil
# ActiveRecord::Base.logger = Logger.new('log/test.db.log')

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

NOW = Time.parse('2011-01-01 00:02:00 +0200')

RSpec.configure do |c|
  c.mock_with :mocha
  c.filter_run_excluding pending: true
  c.include Support::Logger

  c.before :each do
    DatabaseCleaner.start
    Travis::Event.instance_variable_set(:@subscriptions, nil)
    Travis.config.repository.ssl_key.size = 1024
    Time.stubs(:now).returns(NOW)
  end

  c.after :each do
    DatabaseCleaner.clean
  end
end
