require 'spec_helper'
require 'json'

describe Travis::Hub::Handler::Sync do
  include Travis::Testing::Stubs

  let(:payload) { { 'user_id' => 1 } }
  let(:handler) { Travis::Hub::Handler::Sync.new('sync', payload) }

  subject { proc { handler.handle } }

  describe 'handle' do
    it 'syncs the user details with GitHub' do
      Travis.expects(:run_service).with(:github_sync_user, id: 1)
      subject.call
    end
  end
end

