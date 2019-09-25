describe Travis::Addons::Handlers::Webhook do
  let(:handler) { described_class::Notifier.new('build:finished', id: build.id, config: config) }
  let(:repo)    { FactoryGirl.create(:repository) }
  let(:build)   { FactoryGirl.create(:build, repository: repo, state: :passed, config: { notifications: { webhooks: config } }) }
  let(:config)  { { urls: 'http://host.com/target' } }

  before { Travis::Event.setup([:webhook]) }

  describe 'subscription' do
    it 'build:started notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:started', id: build.id)
    end

    it 'build:finished notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:finished', id: build.id)
    end

    it 'build:canceled notifies' do
      described_class.new('build:canceled', id: build.id)
      described_class.expects(:notify)
      Travis::Event.dispatch('build:canceled', id: build.id)
    end

    it 'build:errored notifies' do
      described_class.new('build:errored', id: build.id)
      described_class.expects(:notify)
      Travis::Event.dispatch('build:errored', id: build.id)
    end
  end

  describe 'multiple configs' do
    let(:config)  { [{ urls: 'one' }, { urls: 'two' }] }
    let(:jobs)    { Sidekiq::Queues.jobs_by_queue['webhook'] }
    let(:targets) { jobs.map { |job| job['args'].last['targets'] } }

    before { Travis::Event.dispatch('build:finished', id: build.id) }

    it { expect(jobs.size).to eq 2 }
    it { expect(targets).to eq [['one'], ['two']] }
  end

  describe 'handle?' do
    describe 'is true if targets are present' do
      let(:config) { { urls: 'http://host.com/target' } }
      it { expect(handler.handle?).to eql(true) }
    end

    describe 'is false if no targets are present' do
      let(:config) { false }
      it { expect(handler.handle?).to eql(false) }
    end

    it 'is true if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:webhooks, :finished).returns(true)
      expect(handler.handle?).to eql(true)
    end

    it 'is false if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:webhooks, :finished).returns(false)
      expect(handler.handle?).to eql(false)
    end
  end

  describe 'handle' do
    it 'enqueues a task' do
      handler.expects(:run_task).with(:webhook, is_a(Hash), targets: ['http://host.com/target'], token: 'token')
      handler.handle
    end
  end

  describe 'targets' do
    let(:target) { 'http://host.com/target' }
    let(:other)  { 'http://host.com/other' }

    describe 'returns an array of targets when given a string' do
      let(:config) { target }
      it { expect(handler.targets).to eql [target] }
    end

    describe 'returns an array of targets when given an array' do
      let(:config) { [target] }
      it { expect(handler.targets).to eql [target] }
    end

    describe 'returns an array of targets when given a comma separated string' do
      let(:config) { "#{target}, #{other}" }
      it { expect(handler.targets).to eql [target, other] }
    end

    describe 'returns an array of targets given a string within a hash' do
      let(:config) { { urls: target, on_success: 'change' } }
      it { expect(handler.targets).to eql [target] }
    end

    describe 'returns an array of targets given an array within a hash' do
      let(:config) { { urls: [target], on_success: 'change' } }
      it { expect(handler.targets).to eql [target] }
    end

    describe 'returns an array of targets given a comma separated string within a hash' do
      let(:config) { { urls: "#{target}, #{other}", on_success: 'change' } }
      it { expect(handler.targets).to eql [target, other] }
    end

    describe 'returns an array of targets given a string within a hash on_cancel' do
      let(:config) { { urls: target, on_cancel: 'change' } }
      it { expect(handler.targets).to eql [target] }
    end

    describe 'returns an array of targets given a string within a hash on_errored' do
      let(:config) { { urls: target, on_error: 'change' } }
      it { expect(handler.targets).to eql [target] }
    end
  end
end
