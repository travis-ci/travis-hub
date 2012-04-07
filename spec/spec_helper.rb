ENV["RAILS_ENV"] ||= 'test'

require 'support/payloads'

require 'travis/hub'
require 'travis/support'
require 'stringio'
require 'mocha'

Travis.logger = Logger.new(StringIO.new)

include Mocha::API

RSpec.configure do |c|
  c.mock_with :mocha

  c.before(:each) do
     Time.now.utc.tap { |now| Time.stubs(:now).returns(now) }
   end

  c.after :each do
    Travis.config.notifications.clear
    Travis::Notifications.instance_variable_set(:@subscriptions, nil)
    Travis::Notifications::Handler::Pusher.send(:protected, :queue_for, :payload_for)
  end
end
