describe Travis::Addons::Handlers::Billing do
  let(:build)        { FactoryBot.create(:build) }
  let(:job_config)   { FactoryBot.create(:job_config, repository_id: build.repository_id) }
  let(:job)          { FactoryBot.create(:job, owner:, config_id: job_config.id) }
  let(:owner)        { FactoryBot.create(:user) }
  let!(:request) do
    stub_request(:put, 'http://localhost:9292/usage/executions')
      .to_return(status: 200, body: '', headers: {})
  end

  describe 'handle' do
    let(:handler) { described_class.new(event_name, id: job.id) }

    context 'job:finished' do
      let(:event_name) { 'job:finished' }

      it 'publishes event to billing' do
        ::Sidekiq::Client.any_instance.expects(:push).with do |payload|
          expect(payload['queue']).to   eq('billing')
          expect(payload['class']).to   eq('Travis::Billing::Worker')
          expect(JSON.parse(payload['args'][1])).to eq('Travis::Billing::Services::UsageTracker')
        end
        handler.handle
      end
    end

    context 'job:canceled' do
      let(:event_name) { 'job:canceled' }

      it 'publishes event to billing' do
        ::Sidekiq::Client.any_instance.expects(:push).with do |payload|
          expect(payload['queue']).to   eq('billing')
          expect(payload['class']).to   eq('Travis::Billing::Worker')
          expect(JSON.parse(payload['args'][1])).to eq('Travis::Billing::Services::UsageTracker')
        end
        handler.handle
      end
    end

    context 'job:started' do
      let(:event_name) { 'job:started' }

      it 'publishes event to billing' do
        ::Sidekiq::Client.any_instance.expects(:push).with do |payload|
          expect(payload['queue']).to   eq('billing')
          expect(payload['class']).to   eq('Travis::Billing::Worker')
          expect(JSON.parse(payload['args'][1])).to eq('Travis::Billing::Services::UsageTracker')
        end
        handler.handle
      end
    end
  end
end
