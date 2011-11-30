require 'spec_helper'

describe Travis::Hub::Handler::Worker do
  let(:handler) { @handler ||= Travis::Hub::Handler::Worker.new(:'worker:status', payload) }
  let(:worker)  { stub('worker', :update_attributes! => nil) }
  let(:payload) { [{ :name => 'travis-test-1', :host => 'host', :state => 'ready' }] }

  before :each do
    handler.stubs(:worker_by).returns(worker)
  end

  describe 'handle' do
    it 'updates the worker states and last_seen_at attributes' do
      worker.expects(:ping).with(payload.first)
      handler.handle
    end
  end

  # TODO make the db available here
  #
  # describe 'workers' do
  #   it 'returns workers grouped by their full_name' do
  #     worker = Worker.create(:name => 'worker-1', :host => 'host')
  #     handler.send(:workers)['host:worker-1'].should == worker
  #   end
  # end
  #
  # describe 'worker' do
  #   it 'returns an existing worker instance'
  #   it 'returns a new worker instance'
  # end
end


