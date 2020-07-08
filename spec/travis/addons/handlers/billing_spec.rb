describe Travis::Addons::Handlers::Billing do
  let(:build)        { FactoryGirl.create(:build) }
  let(:job_config)   { FactoryGirl.create(:job_config, repository_id: build.repository_id) }
  let(:job)          { FactoryGirl.create(:job, owner: owner, config_id: job_config.id) }
  let(:owner)        { FactoryGirl.create(:user) }

  before do
    stub_request(:post, 'http://localhost:9292/usage/executions')
      .to_return(status: 200, body: '', headers: {})
  end

  describe 'handle' do
    let(:handler) { described_class.new('job:finished', id: job.id) }

    it 'publishes to billing' do
      handler.handle
    end
  end
end
