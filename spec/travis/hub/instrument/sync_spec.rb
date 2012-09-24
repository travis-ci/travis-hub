require 'spec_helper'
require 'json'

describe Travis::Hub::Instrument::Handler::Sync do
  include Travis::Testing::Stubs

  let(:payload)   { { 'user_id' => 1 } }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:handler)   { Travis::Hub::Handler::Sync.new('sync', payload) }
  let(:event)     { publisher.events.last }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    user = stub(:sync => true)
    User.expects(:find).with(1).returns(user)
    handler.stubs(:receive).returns(true)
    handler.handle
  end

  it 'publishes a payload on handle' do
    event[:payload].should == {
      :msg => %(Travis::Hub::Handler::Sync#handle for user_id="1"),
      :user_id => 1,
      :result => true
    }
  end
end


