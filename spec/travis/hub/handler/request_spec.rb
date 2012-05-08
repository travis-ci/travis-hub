require 'spec_helper'

RSpec::Matchers.define :meter do |meter|
  match do |action|
    expect(&action).to change { Metriks.meter(meter).count }
  end
end

describe Travis::Hub::Handler::Request do
  let(:payload) { { :type => 'push', :credentials => { :login => "user", :token => "12345" }, :request => GITHUB_PAYLOADS['gem-release'] } }
  let(:handler) { Travis::Hub::Handler::Request.new(:request, Hashr.new(payload)) }
  let(:user)    { stub('user', :login => 'user') }

  subject { proc { handler.handle } }

  describe 'handle' do
    describe 'given the request can be authorized' do
      before do
        User.expects(:authenticate_by_token).with('user', '12345').returns(user)
        Request.stubs(:create_from).with('push', GITHUB_PAYLOADS['gem-release'], '12345').returns(true)
      end

      it "creates a valid request" do
        subject.call
      end

      it "increments a counter when a request build message is received" do
        subject.should meter('travis.hub.build_requests.push.received')
      end

      it "increments a counter when a request build message is authenticated" do
        subject.should meter('travis.hub.build_requests.push.received.authenticated')
      end

      it "increments a counter when a request build message is created" do
        subject.should meter('travis.hub.build_requests.push.received.created')
      end

      it "increments a counter when a request build message raises an exception" do
        Request.stubs(:create_from).raises(StandardError)
        proc { handler.handle rescue nil }.should meter('travis.hub.build_requests.push.received.failed')
      end

      it "logs an info message" do
        handler.expects(:info)
        subject.call
      end
    end

    describe 'given the request can not be authorized' do
      before do
        User.expects(:authenticate_by_token).with('user', '12345').returns(nil)
        Request.stubs(:create_from).never
      end

      it "rejects the request" do
        Request.expects(:create_from).never
        subject.call
      end

      it "increments a counter when a request build message is received" do
        subject.should meter('travis.hub.build_requests.push.received')
      end

      it "does not increment a counter when a request build message is not authenticated" do
        subject.should_not meter('travis.hub.build_requests.push.authenticated')
      end

      it "logs a warning" do
        handler.expects(:warn)
        subject.call
      end
    end
  end
end

