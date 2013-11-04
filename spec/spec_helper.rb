ENV["RAILS_ENV"] ||= 'test'

require 'travis/hub'
require 'travis/testing'
require 'travis/support'
require 'support/active_record'
require 'support/payloads'
require 'stringio'
require 'mocha'
require 'travis/testing/matchers'

Travis.logger = Logger.new(StringIO.new)
Travis.services = Travis::Services

include Mocha::API

RSpec.configure do |c|
  c.mock_with :mocha

  c.before(:each) do
     Time.now.utc.tap { |now| Time.stubs(:now).returns(now) }
   end

  c.after :each do
    Travis.config.notifications.clear
    Travis::Event.instance_variable_set(:@subscriptions, nil)
  end
end
