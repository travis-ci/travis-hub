require 'spec_helper'

describe Travis::Hub::Handler::Worker do
  let(:handler) { @handler ||= Travis::Hub::Handler::Worker.new(:event, Hashr.new(payload)) }
  let(:worker)  { stub('worker', :update_attributes! => nil) }
  let(:payload) { { :name => 'worker-1', :host => 'ruby-1.worker.travis-ci.org', :state => :working } }

  before :each do
    Time.now.tap { |now| Time.stubs(:now).returns(now) }
    handler.stubs(:worker).returns(worker)
  end

  describe '#handle' do
    it 'updates the worker state and last_seen_at attributes' do
      worker.expects(:ping!)
      worker.expects(:set_state).with(:working)
      handler.event = :'worker:ping'
      handler.handle
    end

    it 'sets the worker state on worker:started' do
      worker.expects(:set_state).with('started')
      handler.event = :'worker:started'
      handler.handle
    end
  end

  # Sorry, no db available here right now ... but this is testing rails anyway
  #
  # describe 'worker' do
  #   describe 'if a worker with the given name and host attributes exists' do
  #     it 'finds the worker' do
  #       worker = Worker.create!(payload)
  #       handler.send(:worker).should == worker
  #     end
  #   end
  #
  #   describe 'if no worker with the given name and host attributes exists' do
  #     it 'creates a new worker' do
  #       lambda { worker }.should change(Worker, :count).by(1)
  #     end
  #
  #     it 'sets the name attribute' do
  #       worker.name.should == 'worker-1'
  #     end
  #
  #     it 'sets the host attribute' do
  #       worker.host.should == 'ruby-1.worker.travis-ci.org'
  #     end
  #
  #     it 'sets the last_seen_at attribute' do
  #       worker.last_seen_at.should == Time.now
  #     end
  #   end
  # end
end


