require 'spec_helper'
require 'json'

describe Travis::Hub::Instrument::Handler::Request do
  include Travis::Testing::Stubs

  let(:payload)   { { 'type' => 'push', 'credentials' => { 'login' => 'svenfuchs', 'token' => '12345' }, 'payload' => GITHUB_PAYLOADS['gem-release'] } }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:handler)   { Travis::Hub::Handler::Request.new('request', payload) }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    Request.stubs(:receive).returns(repository)
    User.stubs(:authenticate_by).returns(user)
    handler.handle
  end

  it 'publishes a payload on handle' do
    event = publisher.events.last
    event[:payload].should == {
      :msg => %(Travis::Hub::Handler::Request#handle for type=push repository="http://github.com/svenfuchs/gem-release"),
      :type => 'push',
      :data => JSON.parse(payload['payload'])
    }
  end

  it 'publishes a payload on authenticate' do
    event = publisher.events[-2]
    event[:payload][:user].should == { :id => 1, :login => 'svenfuchs' }
    event[:payload][:msg] == %(Travis::Hub::Handler::Request#authenticate success)
  end
end


