describe Travis::Addons::Handlers::Insights do
  let(:build)   { FactoryGirl.create(:build) }
  let(:job)     { FactoryGirl.create(:job) }

  describe 'subscription' do
    before { Travis::Event.setup([:insights]) }

    it 'build:create notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('build:create', id: build.id)
    end

    it 'build:started does not notify' do
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

    it 'job:create notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('job:create', id: job.id)
    end

    it 'job:started does not notify' do
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

  env INSIGHTS_ENABLED: true

  let(:handler) { described_class.new('job:created', id: job.id) }

  let(:data) do
    {
      type: 'Job',
      id: job.id,
      owner_type: job.owner_type,
      owner_id: job.owner_id,
      repository_id: job.repository_id,
      created_at: job.created_at,
      started_at: nil,
      finished_at: nil,
      state: :created
    }
  end

  it { expect(handler.handle?).to be true }

  it 'handle' do
    ::Sidekiq::Client.expects(:push).with(
      'queue' => 'insights',
      'class' => 'Travis::Insights::Worker',
      'args'  => [:event, event: 'job:created', data: data]
    )
    handler.handle
  end
end
