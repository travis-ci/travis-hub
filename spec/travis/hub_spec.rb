require 'spec_helper'

describe Travis::Hub do
  let(:hub)     { Travis::Hub.new }
  let(:payload) { '{ "foo": "bar", "uuid": "2d931510-d99f-494a-8c67-87feb05e1594" }' }
  let(:message) { stub('message', :ack => nil, :properties => stub('properties', :type => 'request') ) } # TODO what are the real event types?
  let(:handler) { stub('handler', :handle => nil) }

  before :each do
    Travis::Hub::Handler.stubs(:for).returns(handler)
  end

  describe 'decode' do
    it 'decodes a json payload' do
      hub.send(:decode, '{ "id": 1 }')['id'].should == 1
    end
  end

  describe 'receive' do
    it 'sets the given uuid to the current thread' do
      hub.send(:receive, message, payload)
      Thread.current[:uuid].should == '2d931510-d99f-494a-8c67-87feb05e1594'
    end

    describe 'with no exception being raised' do
      it 'gets a handler for the event type and payload' do
        Travis::Hub::Handler.expects(:for).with('request', { 'foo' => 'bar' }).returns(handler)
        hub.receive(message, payload)
      end

      it 'handles the event' do
        handler.expects(:handle)
        hub.receive(message, payload)
      end

      it 'acknowledges the message' do
        message.expects(:ack)
        hub.receive(message, payload)
      end
    end

    describe 'with an exception being raised' do
      before :each do
        handler.expects(:handle).raises(StandardError.new('message'))
        $stdout = StringIO.new
      end

      after :each do
        $stdout = STDOUT
      end

      it 'outputs the exception' do
        hub.receive(message, payload)
        $stdout.string.should =~ /message/
      end

      it 'acknowledges the message' do
        message.expects(:ack)
        hub.receive(message, payload)
      end

      it 'notifies the error reporter' do
        Travis::Exceptions::Reporter.expects(:enqueue).with do |exception|
          $stdout = STDOUT
          exception.should be_instance_of(Travis::Hub::Error)
          exception.message.should =~ /message/
        end
        hub.receive(message, payload)
      end
    end
  end
end
