require "spec_helper"

describe Travis::Addons::Config do
  let(:build) { FactoryGirl.build(:build) }

  subject { described_class.new(build, config) }

  describe "#[]" do
    context "when invalid config is given" do
      let(:config) { 'email:false' }

      it "does not raise exception" do
        expect { subject[:email] }.to_not raise_error
      end
    end
  end
end
