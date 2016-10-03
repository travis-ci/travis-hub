require 'travis/hub'
require 'time'

require 'support/factories'
require 'support/context'
require 'support/database_cleaner'
require 'travis/hub/stages/support'

require 'webmock'
require 'webmock/rspec'

# Travis::Hub::Context.new

# Travis::Event.setup
# Travis::Hub::Database.connect(ActiveRecord::Base, Travis::Hub::Config.new.database.to_h)
# ActiveRecord::Base.logger = Logger.new('log/test.db.log')

NOW = Time.parse('2011-01-01 00:02:00 +0200')

RSpec.configure do |c|
  c.mock_with :mocha
  c.filter_run_excluding pending: true
  c.include Support::Context
  c.include Support::DatabaseCleaner

  c.before do
    Travis::Event.instance_variable_set(:@subscriptions, nil)
    # Travis::Addons.setup({ host: 'host.com', encryption: { key: 'secret' * 10 } }, logger)
    Time.stubs(:now).returns(NOW)
  end
end
