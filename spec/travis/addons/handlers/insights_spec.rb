describe Travis::Addons::Handlers::Insights do
  let(:owner)   { FactoryGirl.create(:user, login: 'user') }
  let(:build)   { FactoryGirl.create(:build, owner: owner, repository: repository) }
  let(:job)     { FactoryGirl.create(:job, owner: owner, repository: repository) }
  let(:repository) { FactoryGirl.create(:repository) }

  describe 'subscription' do
    before { Travis::Event.setup([:insights]) }

    it 'build:created notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('build:created', id: build.id)
    end

    it 'build:started notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('build:started', id: build.id)
    end

    it 'build:finished notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('build:finished', id: build.id)
    end

    it 'build:restarted notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('build:restarted', id: build.id)
    end

    it 'job:created notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('job:created', id: job.id)
    end

    it 'job:received does not notify' do
      described_class.expects(:notify).never
      Travis::Event.dispatch('job:received', id: job.id)
    end

    it 'job:started notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('job:started', id: job.id)
    end

    it 'job:finished notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('job:finished', id: job.id)
    end

    it 'job:restarted notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('job:restarted', id: job.id)
    end
  end

  let(:handler) { described_class.new(event, id: job.id) }

  let(:data) do
    {
      type: 'Job',
      id: job.id,
      owner_type: job.owner_type,
      owner_id: job.owner_id,
      repository_id: job.repository_id,
      private: !!job.private?,
      state: :created,
      created_at: job.created_at,
      started_at: nil,
      finished_at: nil
    }
  end

  describe 'job:created via Sidekiq' do
    let(:event) { 'job:created' }
    it 'handle' do
      ::Sidekiq::Client.any_instance.expects(:push).with(
        'queue' => 'insights',
        'class' => 'Travis::Insights::Worker',
        'args'  => [:event, event: 'job:created', data: data],
        'dead'  => false
      )
      handler.handle
    end
  end

  describe 'job:created via HTTP' do
    config insights: { url: 'https://insights.travis-ci.com', token: 'token' }

    env ROLLOUT: 'insights_http'
    env ROLLOUT_INSIGHTS_HTTP_OWNERS: 'user'

    let(:event) { 'job:created' }

    it 'handle' do
      stub_request(:post, 'https://insights.travis-ci.com/events?source=hub').with do |r|
        expect(JSON.parse(r.body)['event']).to eq 'job:created'
        expect(r.headers['Authorization']).to eq 'Token token="token"'
        expect(r.headers['Content-Type']).to eq 'application/json'
      end
      handler.handle
    end
  end

  describe 'job:canceled' do
    let(:event) { 'job:canceled' }
    it 'handle' do
      ::Sidekiq::Client.any_instance.expects(:push).with(
        'queue' => 'insights',
        'class' => 'Travis::Insights::Worker',
        'args'  => [:event, event: 'job:finished', data: data],
        'dead'  => false
      )
      handler.handle
    end
  end

  describe 'sends restarted_at if present' do
    let(:event) { 'job:created' }
    let(:restarted_at) { Time.now + 120  }
    before { job.update_attributes(restarted_at: restarted_at) }
    it 'handle' do
      ::Sidekiq::Client.any_instance.expects(:push).with(
        'queue' => 'insights',
        'class' => 'Travis::Insights::Worker',
        'args'  => [:event, event: 'job:created', data: data.merge(created_at: restarted_at)],
        'dead'  => false
      )
      handler.handle
    end
  end
end
