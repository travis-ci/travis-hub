describe Travis::Addons::Handlers::Billing do
  let(:build)        { FactoryGirl.create(:build) }
  let(:job_config)   { FactoryGirl.create(:job_config, repository_id: build.repository_id) }
  let(:job)          { FactoryGirl.create(:job, owner: owner, config_id: job_config.id) }
  let(:owner)        { FactoryGirl.create(:user) }
  let!(:request) do
    stub_request(:put, 'http://localhost:9292/usage/executions')
      .to_return(status: 200, body: '', headers: {})
  end

  describe 'handle' do
    let(:handler) { described_class.new(event_name, id: job.id) }

    context 'job:finished' do
      let(:event_name) { 'job:finished' }

      it 'publishes event to billing' do
        expect(Travis::Sidekiq).to receive(:billing)
        handler.handle
      end
    end

    context 'job:canceled' do
      let(:event_name) { 'job:canceled' }

      it 'publishes event to billing' do
        expect(Travis::Sidekiq).to receive(:billing)
        handler.handle
      end
    end

    context 'job:started' do
      let(:event_name) { 'job:started' }

      it 'publishes event to billing' do
        expect(Travis::Sidekiq).to receive(:billing)
        handler.handle
      end
    end
  end
end
