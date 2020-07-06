describe Travis::Addons::Handlers::Billing do
  let(:config) { { billing: { url: 'http://localhost:9292', auth_key: 't0Ps3Cr3t' } } }
  let(:build) { FactoryGirl.create(:build) }
  let(:job)   { FactoryGirl.create(:job, owner: owner) }
  let(:owner) { FactoryGirl.create(:user) }

  before do
    stub_request(:post, "http://localhost:9292/usage/executions").
         to_return(:status => 200, :body => "", :headers => {})
  end

  describe 'handle' do
    let(:handler) { described_class.new('job:finished', id: job.id, config: config) }

    it 'publishes to billing' do
      handler.handle
    end
  end
end
