require 'spec_helper'
require 'json'

RSpec::Matchers.define :meter do |meter|
  match do |action|
    expect(&action).to change { Metriks.meter(meter).count }
  end
end

describe Travis::Hub::Handler::Request do
  include Travis::Testing::Stubs

  let(:data)    { JSON.parse(GITHUB_PAYLOADS['gem-release']) }
  let(:payload) { { :type => 'push', :credentials => { :login => 'svenfuchs', :token => '12345' }, :payload => data } }
  let(:handler) { Travis::Hub::Handler::Request.new(:request, Hashr.new(payload)) }

  subject { proc { handler.handle } }

  before :each do
    Request.stubs(:receive)
  end

  describe 'handle' do
    it 'tries to authenticates the user' do
      User.expects(:authenticate_by_token).with('svenfuchs', '12345').returns(nil)
      subject.call
    end

    describe 'given the request can be authorized' do
      before :each do
        User.stubs(:authenticate_by_token).returns(user)
      end

      it "creates the request" do
        Request.expects(:receive).with('push', Hashr.new(data), '12345').returns(true)
        subject.call
      end
    end

    describe 'given the request can not be authorized' do
      before do
        User.stubs(:authenticate_by_token).returns(nil)
      end

      it "rejects the request" do
        Request.expects(:receive).never
        subject.call
      end
    end
  end
end

