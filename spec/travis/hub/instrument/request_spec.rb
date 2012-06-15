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
    publisher.events.last.should == {
      :msg => %(Travis::Hub::Handler::Request#handle for type=push repository="http://github.com/svenfuchs/gem-release"),
      :result => { 'repository' => { 'id' => 1, 'slug' => 'svenfuchs/minimal' } },
      :type => 'push',
      :data => JSON.parse(payload['payload']),
      :uuid => Travis.uuid
    }
  end

  it 'publishes a payload on authenticate' do
    publisher.events.first.should == {
      :msg => %(Travis::Hub::Handler::Request#authenticate success),
      :result => { 'user' => { 'id' => 1, 'login' => 'svenfuchs' } },
      :uuid => Travis.uuid
    }
  end
end


