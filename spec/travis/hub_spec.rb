require 'spec_helper'

describe Travis::Hub do
  let(:hub)     { Travis::Hub.new }
  let(:payload) { hub.send(:decode, '{ "id": 1 }') }

  describe 'decode' do
    it 'decodes a json payload' do
      payload['id'].should == 1
    end
  end

  describe 'handler_for' do
    describe 'given an event namespaced job:*' do
      events = %w(
        job:config:started
        job:config:finished
        job:test:started
        job:test:log
        job:test:finished
      )

      events.each do |event|
        it "returns a Job handler for #{event.inspect}" do
          hub.send(:handler_for, event, payload).should be_kind_of(Travis::Handler::Job)
        end
      end
    end

    describe 'given an event namespaced worker:*' do
      events = %w(
        worker:ping
        worker:start
        worker:finish
      )

      events.each do |event|
        it "returns a Worker handler for #{event.inspect}" do
          hub.send(:handler_for, event, payload).should be_kind_of(Travis::Handler::Worker)
        end
      end
    end
  end
end
