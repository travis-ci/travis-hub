require 'spec_helper'

describe Travis::Hub::Handler::Request do
  let(:handler) { Travis::Hub::Handler::Request.new(:request, Hashr.new(payload)) }
  let(:user)    { stub('user', :login => 'user') }
  let(:token)   { stub('token', :user => user) }
  let(:payload) do
    {
      :credentials => {
        :login => "user",
        :token => "12345"
      },
      :request => GITHUB_PAYLOADS['gem-release']
    }
  end
  let(:github_request) { MultiJson.decode(payload[:request]) }

  describe '#handle' do
    describe 'authorized' do
      before do
        Request.stubs(:create_from).with(github_request, '12345').returns(true)
        Token.stubs(:find_by_token).with('12345').returns(token)
      end

      it "creates a valid request" do
        handler.handle
      end
    end

    describe 'not authorized' do
      let(:user)  { stub('user_two', :login => 'user2') }
      let(:token) { stub('token', :user => user) }

      before do
        Token.stubs(:find_by_token).with('12345').returns(token)
      end

      it "rejects the request" do
        Request.expects(:create_from).never
        handler.handle
      end
    end
  end
end

