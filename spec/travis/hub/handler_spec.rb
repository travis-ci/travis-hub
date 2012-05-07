require 'spec_helper'

describe Travis::Hub::Handler do
  let(:payload) { { :name => 'worker-1', :host => 'ruby-1.worker.travis-ci.org' } }

  describe '.for' do
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
          Travis::Hub::Handler.for(event, payload).should be_kind_of(Travis::Hub::Handler::Job)
        end
      end
    end

    describe 'given an event namespaced worker:*' do
      events = %w(
        worker:status
        worker:start
        worker:finish
      )

      events.each do |event|
        it "returns a Worker handler for #{event.inspect}" do
          Travis::Hub::Handler.for(event, payload).should be_kind_of(Travis::Hub::Handler::Worker)
        end
      end
    end

    describe "given a configure job" do
      it "should create a Configure handler" do
        Travis::Hub::Handler.for('configure', {}).should be_instance_of(Travis::Hub::Handler::Configure)
      end
    end

    describe "without an event name" do
      it "should fetch the type from the payload" do
        Travis::Hub::Handler.for(nil, {'type' => 'configure'}).should be_instance_of(Travis::Hub::Handler::Configure)
      end

      describe "for pull and push requests" do
        it "should fetch a Request handler for pull requests" do
          Travis::Hub::Handler.for(nil, {'type' => 'pull_request'}).should be_instance_of(Travis::Hub::Handler::Request)
        end
      end
    end
  end
end
