require 'spec_helper'

describe Travis::Hub do
  let(:hub)     { Travis::Hub.new }
  let(:payload) { hub.send(:decode, '{ "id": 1 }') }

  describe 'decode' do
    it 'decodes a json payload' do
      payload['id'].should == 1
    end
  end
end
