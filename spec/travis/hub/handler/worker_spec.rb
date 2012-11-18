require 'spec_helper'

describe Travis::Hub::Handler::Worker do
  let(:handler) { Travis::Hub::Handler::Worker.new('worker:status', payload) }

  describe 'handle (old api, hash payload)' do
    let(:payload) { { :name => 'travis-test-1', :host => 'host', :state => 'ready' } }

    it 'updates the worker status' do
      Travis.expects(:run_service).with(:update_workers, reports: [payload])
      handler.handle
    end
  end

  describe 'handle (old api, array payload)' do
    let(:payload) { [{ :name => 'travis-test-1', :host => 'host', :state => 'ready' }] }

    it 'updates the worker states and last_seen_at attributes (array payload)' do
      Travis.expects(:run_service).with(:update_workers, reports: payload)
      handler.handle
    end
  end

  describe 'handle (new api)' do
    let(:payload) { { 'workers' => [{ :name => 'travis-test-1', :host => 'host', :state => 'ready' }] } }

    it 'updates the worker states and last_seen_at attributes' do
      Travis.expects(:run_service).with(:update_workers, reports: payload['workers'])
      handler.handle
    end
  end
end


