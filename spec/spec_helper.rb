require 'travis/hub'
require 'time'

require 'database_cleaner'
require 'support/factories'
require 'support/context'
require 'travis/hub/handler/metrics'

Travis::Event.setup
Travis::Hub::Database.connect(Travis::Hub::Config.new.database.to_h)
# ActiveRecord::Base.logger = Logger.new('log/test.db.log')

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

NOW = Time.parse('2011-01-01 00:02:00 +0200')

RSpec.configure do |c|
  c.mock_with :mocha
  c.filter_run_excluding pending: true
  c.include Support::Context

  c.before :each do
    DatabaseCleaner.start
    Travis::Event.instance_variable_set(:@subscriptions, nil)
    Travis::Addons.setup({ host: 'host.com', encryption: { key: 'secret' * 10 } }, logger)
    Time.stubs(:now).returns(NOW)
  end

  c.after :each do
    DatabaseCleaner.clean
  end
end
