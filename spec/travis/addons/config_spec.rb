require 'spec_helper'

describe Travis::Addons::Config do
  subject { described_class.new(build, config) }

  let(:build) { FactoryBot.build(:build) }

  describe '#[]' do
    context 'when invalid config is given' do
      let(:config) { 'email:false' }

      it 'does not raise exception' do
        expect { subject[:email] }.not_to raise_error
      end
    end
  end
end
