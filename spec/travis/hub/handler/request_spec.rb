require 'spec_helper'
require 'json'

RSpec::Matchers.define :meter do |meter|
  match do |action|
    expect(&action).to change { Metriks.meter(meter).count }
  end
end

describe Travis::Hub::Handler::Request do
  include Travis::Testing::Stubs

  let(:user_details) { { 'login' => 'svenfuchs', 'token' => '12345' } }
  let(:user)         { stub(user_details.merge('id' => 1)) }
  let(:payload)      { { 'type' => 'push', 'credentials' => user_details, 'payload' => GITHUB_PAYLOADS['gem-release'] } }
  let(:handler)      { Travis::Hub::Handler::Request.new('request', payload) }

  subject { proc { handler.handle } }

  before :each do
    Travis::Services::Requests::Receive.any_instance.stubs(:run)
  end

  describe 'handle' do
    it 'tries to authenticates the user' do
      User.expects(:authenticate_by).with(user_details).returns(user)
      subject.call
    end

    describe 'given the request can be authorized' do
      before :each do
        User.stubs(:authenticate_by).returns(user)
      end

      it "creates the request" do
        params = { :event_type => 'push', :payload => JSON.parse(payload['payload']), :token => '12345' }
        Travis::Services::Requests::Receive.expects(:new).with(user, params).returns(stub(:run => nil))
        subject.call
      end
    end

    describe 'given the request payload is nil' do
      let(:payload) { { 'type' => 'push', 'credentials' => user_details, 'payload' => nil } }

      it "raises a ProcessingError" do
        expect { subject.call }.to raise_error(Travis::Hub::Handler::Request::ProcessingError)
      end
    end

    describe 'given the request can not be authorized' do
      before do
        User.stubs(:authenticate_by).returns(nil)
      end

      it "rejects the request" do
        Request.expects(:receive).never
        subject.call
      end
    end
  end
end

