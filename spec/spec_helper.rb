ENV['RAILS_ENV'] ||= 'test'

require 'simplecov' if ENV['RAILS_ENV'] == 'test' && ENV['COVERAGE']

require 'travis/hub'
require 'travis/support'
require 'support/active_record'
require 'support/factories'
require 'support/formats'
require 'support/payloads'
require 'support/stubs'
require 'stringio'
require 'mocha'

Travis.logger = Logger.new(StringIO.new)
Travis.services = Travis::Services

include Mocha::API

RSpec.configure do |c|
  c.mock_with :mocha

  c.before(:each) do
    Time.now.utc.tap { |now| Time.stubs(:now).returns(now) }
    Travis.config.repository.ssl_key.size = 1024
  end

  c.after :each do
    Travis.config.notifications.clear
    Travis::Event.instance_variable_set(:@subscriptions, nil)
  end
end
