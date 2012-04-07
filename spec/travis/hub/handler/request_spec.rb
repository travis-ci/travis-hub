require 'spec_helper'

describe Travis::Hub::Handler::Request do
  let(:handler) { Travis::Hub::Handler::Request.new(:request, Hashr.new(payload)) }
  let(:user)    { stub('user', :login => 'user') }
  let(:payload) do
    {
      :credentials => {
        :login => "user",
        :token => "12345"
      },
      :request => GITHUB_PAYLOADS['gem-release']
    }
  end

  describe '#handle' do
    describe 'authorized' do
      before do
        Request.stubs(:create_from).with(payload, '12345').returns(true)
        Token.stubs(:find_by_token).with('12345').returns(user)
      end

      it "creates a valid request" do
        handler.handle
      end
    end

    describe 'not authorized' do
      let(:another_user) { stub('user_two', :login => 'user2') }

      before do
        Token.stubs(:find_by_token).with('12345').returns(another_user)
      end

      it "rejects the request" do
        handler.handle
      end
    end
  end
end

