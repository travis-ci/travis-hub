ENV['ENV'] = 'test'
ENV.delete('DATABASE_URL')

require 'support/keys'
require 'travis/hub'
require 'travis/hub/api'
require 'date'

require 'support/context'
require 'support/database_cleaner'
require 'support/env'
require 'support/factories'
require 'support/features'

require 'mocha'
require 'bourne' # TODO use rspec stubs/expectations
require 'sinatra/test_helpers'
require 'webmock'
require 'webmock/rspec'
require 'pry'

Travis::Hub::Context.new

# Travis::Event.setup
# Travis::Hub::Database.connect(ActiveRecord::Base, Travis::Hub::Config.new.database.to_h)
# ActiveRecord::Base.logger = Logger.new('log/test.db.log')

RSpec.configure do |c|
  c.mock_with :mocha
  c.filter_run_excluding pending: true
  c.include Support::Context
  c.include Support::DatabaseCleaner
  c.include Support::Env
  c.include Support::Features
  c.include Sinatra::TestHelpers, :include_sinatra_helpers

  c.before do
    Travis::Event.instance_variable_set(:@subscriptions, nil)
    Time.stubs(:now).returns(NOW)
    Time.stubs(:new).returns(NOW)
  end
end

NOW = Time.parse('2011-01-01 00:02:00 +0200')
