require 'spec_helper'

describe Travis::Hub::Handler::Worker do
  let(:handler) { Travis::Hub::Handler::Worker.new('worker:status', payload) }

  describe 'handle (old api, hash payload)' do
    let(:payload) { { :name => 'travis-test-1', :host => 'host', :state => 'ready' } }

    it 'updates the worker status' do
      Worker::Status.expects(:update).with([payload])
      handler.handle
    end
  end

  describe 'handle (old api, array payload)' do
    let(:payload) { [{ :name => 'travis-test-1', :host => 'host', :state => 'ready' }] }

    it 'updates the worker states and last_seen_at attributes (array payload)' do
      Worker::Status.expects(:update).with(payload)
      handler.handle
    end
  end

  describe 'handle (new api)' do
    let(:payload) { { 'workers' => [{ :name => 'travis-test-1', :host => 'host', :state => 'ready' }] } }

    it 'updates the worker states and last_seen_at attributes' do
      Worker::Status.expects(:update).with(payload['workers'])
      handler.handle
    end
  end
end


