require 'spec_helper'

describe Travis::Hub do
  let(:hub)     { Travis::Hub.new }

  describe 'decode' do
    it 'decodes a json payload' do
      hub.send(:decode, '{ "id": 1 }')['id'].should == 1
    end
  end
end
