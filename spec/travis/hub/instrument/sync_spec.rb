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
    events.first[:payload].should == {
      :msg => %(Travis::Hub::Handler::Sync#handle received for user_id="1"),
      :user_id => 1
    }
  end

  it 'publishes a completed payload on handle' do
    events.last[:payload].should == {
      :msg => %(Travis::Hub::Handler::Sync#handle completed for user_id="1" in 5 seconds),
      :user_id => 1,
      :result => true
    }
  end
end


