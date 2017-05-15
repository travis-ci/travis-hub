ENV['ENV'] = 'test'

require 'travis/hub'
require 'date'

require 'support/factories'
require 'support/context'
require 'support/database_cleaner'

require 'mocha'
require 'bourne' # TODO use rspec stubs/expectations

require 'webmock'
require 'webmock/rspec'

Travis::Hub::Context.new

NOW = Time.parse('2011-01-01 00:02:00 +0200')

RSpec.configure do |c|
  c.mock_with :mocha
  c.filter_run_excluding pending: true
  c.include Support::Context
  c.include Support::DatabaseCleaner

  c.before do
    Travis::Event.instance_variable_set(:@subscriptions, nil)
    Time.stubs(:now).returns(NOW)
  end
end
