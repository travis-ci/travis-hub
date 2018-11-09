describe Travis::Addons::Handlers::Insights do
  let(:build)   { FactoryGirl.create(:build) }
  let(:job)     { FactoryGirl.create(:job, owner_id: 1, owner_type: 'User', repository_id: 1) }

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
      state: :created,
      created_at: job.created_at,
      started_at: nil,
      finished_at: nil
    }
  end

  describe 'job:created' do
    let(:event) { 'job:created' }
    it 'handle' do
      ::Sidekiq::Client.any_instance.expects(:push).with(
        'queue' => 'insights',
        'class' => 'Travis::Insights::Worker',
        'args'  => [:event, event: 'job:created', data: data]
      )
      handler.handle
    end
  end

  describe 'job:canceled' do
    let(:event) { 'job:canceled' }
    it 'handle' do
      ::Sidekiq::Client.any_instance.expects(:push).with(
        'queue' => 'insights',
        'class' => 'Travis::Insights::Worker',
        'args'  => [:event, event: 'job:finished', data: data]
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
        'args'  => [:event, event: 'job:created', data: data.merge(created_at: restarted_at)]
      )
      handler.handle
    end
  end
end
