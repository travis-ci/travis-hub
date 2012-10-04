require 'spec_helper'
require 'json'

describe Travis::Hub::Instrument::Handler::Request do
  include Travis::Testing::Stubs

  let(:payload)   { { 'type' => 'push', 'credentials' => { 'login' => 'svenfuchs', 'token' => '12345' }, 'payload' => GITHUB_PAYLOADS['gem-release'] } }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:handler)   { Travis::Hub::Handler::Request.new('request', payload) }

  before :each do
    Travis::Hub::Instrument::Handler::Request.any_instance.stubs(:duration).returns(5)
    Travis::Notification.publishers.replace([publisher])
    Travis::Services::Requests::Receive.any_instance.stubs(:run)
    User.stubs(:authenticate_by).returns(user)
    handler.handle
  end

  it 'publishes a received payload on handle' do
    event = publisher.events.first
    event[:payload].should == {
      :msg => %(Travis::Hub::Handler::Request#handle received for type=push repository="http://github.com/svenfuchs/gem-release"),
      :type => 'push',
      :data => JSON.parse(payload['payload'])
    }
  end

  it 'publishes a completed payload on handle' do
    event = publisher.events.last
    event[:payload].should == {
      :msg => %(Travis::Hub::Handler::Request#handle completed for type=push repository="http://github.com/svenfuchs/gem-release" in 5 seconds),
      :type => 'push',
      :data => JSON.parse(payload['payload'])
    }
  end

  it 'publishes a payload on authenticate' do
    event = publisher.events[-2]
    event[:payload][:user].should == { :id => 1, :login => 'svenfuchs' }
    event[:payload][:msg] == %(Travis::Hub::Handler::Request#authenticate for svenfuchs succeeded)
  end
end


