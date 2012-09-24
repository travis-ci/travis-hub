require 'spec_helper'
require 'json'

describe Travis::Hub::Handler::Sync do
  include Travis::Testing::Stubs

  let(:payload)      { { 'user_id' => 1 } }
  let(:handler)      { Travis::Hub::Handler::Sync.new('sync', payload) }

  subject { proc { handler.handle } }

  before :each do
    handler.stubs(:receive)
  end

  describe 'handle' do
    it 'syncs the user details with GitHub' do
      user = stub(:sync => true)
      User.expects(:find).with(1).returns(user)

      subject.call
    end
  end
end

