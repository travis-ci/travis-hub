require 'spec_helper'

describe Travis::Hub::Handler::Worker do
  let(:handler) { @handler ||= Travis::Hub::Handler::Worker.new(:event, Hashr.new(payload)) }
  let(:worker)  { stub('worker', :update_attributes! => nil) }
  let(:payload) { {
    :travis-development-1 => { :name => 'travis-development-1', :host => 'Svens-MacBook-Pro-2.local', :state => 'ready' },
    :travis-development-2 => { :name => 'travis-development-2', :host => 'Svens-MacBook-Pro-2.local', :state => 'ready' }
  } }

  before :each do
    handler.stubs(:worker).returns(worker)
  end

  describe 'handle' do
    it 'updates the worker states and last_seen_at attributes' do
      worker.expects(:ping!)
      worker.expects(:set_state).with(:working)
      handler.event = :'worker:ping'
      handler.handle
    end

    it 'sets the worker states on worker:started' do
      worker.expects(:set_state).with('started')
      handler.event = :'worker:started'
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


