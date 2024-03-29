describe Travis::Addons::Handlers::Insights do
  let(:build)   { FactoryBot.create(:build, repository:) }
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
  let(:job) { FactoryBot.create(:job, owner_id: 1, owner_type: 'User', repository:) }
  let(:repository) { FactoryBot.create(:repository) }

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
  let(:handler) { described_class.new(event, id: job.id) }

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

  describe 'job:created' do
    let(:event) { 'job:created' }

    it 'handle' do
      ::Sidekiq::Client.any_instance.expects(:push).with(
        'queue' => 'insights',
        'class' => 'Travis::Insights::Worker',
        'args' => [:event, { event: 'job:created', data: }].map! { |arg| arg.to_json },
        'dead' => false
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
        'args' => [:event, { event: 'job:finished', data: }].map! { |arg| arg.to_json },
        'dead' => false
      )
      handler.handle
    end
  end

  describe 'sends restarted_at if present' do
    let(:event) { 'job:created' }
    let(:restarted_at) { Time.now + 120 }

    before { job.update(restarted_at:) }

    it 'handle' do
      ::Sidekiq::Client.any_instance.expects(:push).with(
        'queue' => 'insights',
        'class' => 'Travis::Insights::Worker',
        'args' => [:event, { event: 'job:created', data: data.merge(created_at: restarted_at) }].map! { |arg| arg.to_json },
        'dead' => false
      )
      handler.handle
    end
  end
end
