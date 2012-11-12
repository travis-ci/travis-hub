require 'spec_helper'
require 'json'

describe Travis::Hub::Instrument::Handler::Sync do
  include Travis::Testing::Stubs

  let(:payload)   { { 'user_id' => 1 } }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:handler)   { Travis::Hub::Handler::Sync.new('sync', payload) }
  let(:events)    { publisher.events }

  before :each do
    Travis::Hub::Instrument::Handler::Sync.any_instance.stubs(:duration).returns(5)
    Travis::Notification.publishers.replace([publisher])
    user = stub(:sync => true)
    User.expects(:find).with(1).returns(user)
    handler.stubs(:receive).returns(true)
    handler.handle
  end

  it 'publishes a received payload on handle' do
    event = events.first
    event.should publish_instrumentation_event(
      :event => 'travis.hub.handler.sync.handle:received',
      :message => %(Travis::Hub::Handler::Sync#handle:received for user_id="1"),
    )
    event[:data].should == {
      :user_id => 1
    }
  end

  it 'publishes a completed payload on handle' do
    event = events.last
    event.should publish_instrumentation_event(
      :event => 'travis.hub.handler.sync.handle:completed',
      :message => %(Travis::Hub::Handler::Sync#handle:completed for user_id="1"),
      :result => true
    )
    event[:data].should == {
      :user_id => 1
    }
  end
end


