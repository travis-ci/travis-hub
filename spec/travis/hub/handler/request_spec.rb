require 'spec_helper'

describe Travis::Hub::Handler::Request do
  let(:handler) { Travis::Hub::Handler::Request.new(:request, Hashr.new(payload)) }
  let(:user)    { stub('user', :login => 'user') }
  let(:token)   { stub('token', :user => user) }
  let(:payload) { { :type => 'push', :credentials => { :login => "user", :token => "12345" }, :request => GITHUB_PAYLOADS['gem-release'] } }

  describe '#handle' do
    describe 'authorized' do
      before do
        Request.stubs(:create_from).with('push', GITHUB_PAYLOADS['gem-release'], '12345').returns(true)
        User.expects(:authenticate_by_token).with('user', '12345').returns(user)
      end

      it "creates a valid request" do
        handler.handle
      end

      it "increments a counter when a request build message is received" do
        expect { handler.handle }.to change { Metriks.meter('travis.hub.build_requests.push.received').count }
      end

      it "increments a counter when a request build message is authenticated" do
        expect { handler.handle }.to change { Metriks.meter('travis.hub.build_requests.push.received.authenticated').count }
      end

      it "increments a counter when a request build message is created" do
        expect { handler.handle }.to change { Metriks.meter('travis.hub.build_requests.push.received.created').count }
      end

      it "increments a counter when a request build message raises an exception" do
        Request.stubs(:create_from).raises(StandardError)
        expect { handler.handle rescue nil }.to change { Metriks.meter('travis.hub.build_requests.push.received.failed').count }
      end

      it "logs an info message" do
        handler.expects(:info)
        handler.handle
      end
    end

    describe 'not authorized' do
      let(:user)  { stub('user_two', :login => 'user2') }
      let(:token) { stub('token', :user => user) }

      before do
        User.expects(:authenticate_by_token).with('user', '12345').returns(nil)
      end

      it "rejects the request" do
        Request.expects(:create_from).never
        handler.handle
      end

      it "increments a counter when a request build message is received" do
        expect { handler.handle }.to change { Metriks.meter('travis.hub.build_requests.push.received').count }
      end

      it "does not increment a counter when a request build message is not authenticated" do
        expect { handler.handle }.not_to change { Metriks.meter('travis.hub.build_requests.push.authenticated').count }
      end

      it "logs a warning" do
        handler.expects(:warn)
        handler.handle
      end
    end
  end
end

