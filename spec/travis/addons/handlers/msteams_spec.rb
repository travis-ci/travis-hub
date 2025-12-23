describe Travis::Addons::Handlers::Msteams do
  let(:handler) { described_class::Notifier.new('build:finished', id: build.id, config:) }
  let(:repo)    { FactoryBot.create(:repository) }
  let(:build)   { FactoryBot.create(:build, repository: repo, state: :passed, config: { notifications: { msteams: config } }) }
  let(:config)  { { rooms: 'https://outlook.office.com/webhook/test' } }

  before { Travis::Event.setup([:msteams]) }

  describe 'subscription' do
    it 'build:started does not notify' do
      described_class.expects(:notify).never
      Travis::Event.dispatch('build:started', id: build.id)
    end

    it 'build:finished notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:finished', id: build.id)
    end
  end

  describe 'multiple configs' do
    let(:config)  { [{ rooms: 'https://outlook.office.com/webhook/one' }, { rooms: 'https://outlook.office.com/webhook/two' }] }
    let(:jobs)    { Sidekiq::Queues.jobs_by_queue['msteams'] }
    let(:targets) { jobs.map { |job| JSON.parse(job['args'].last)['targets'] } }

    before { Travis::Event.dispatch('build:finished', id: build.id) }

    it { expect(jobs.size).to eq 2 }
    it { expect(targets).to eq [['https://outlook.office.com/webhook/one'], ['https://outlook.office.com/webhook/two']] }
  end

  describe 'handle?' do
    it 'is true if rooms are present' do
      expect(handler.handle?).to eql(true)
    end

    it 'is false if no rooms are present' do
      handler.stubs(:targets).returns([])
      expect(handler.handle?).to eql(false)
    end

    it 'is false if the build is a pull request and config opts out' do
      build.update(event_type: 'pull_request')
      handler = described_class::Notifier.new('build:finished', id: build.id, config: { rooms: 'https://outlook.office.com/webhook/test', on_pull_requests: false })
      expect(handler.handle?).to eql(false)
    end

    it 'is true if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:msteams, :finished).returns(true)
      expect(handler.handle?).to eql(true)
    end

    it 'is false if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:msteams, :finished).returns(false)
      expect(handler.handle?).to eql(false)
    end
  end

  describe 'handle' do
    it 'enqueues a task with correct parameters' do
      handler.expects(:run_task).with(:msteams, is_a(Hash), targets: ['https://outlook.office.com/webhook/test'], token: 'token')
      handler.handle
    end

    it 'uses custom MS Teams serializer for payload' do
      payload = handler.payload
      expect(payload[:type]).to eq('message')
      expect(payload[:attachments]).to be_an(Array)
      expect(payload[:attachments][0][:contentType]).to eq('application/vnd.microsoft.card.adaptive')
    end
  end

  describe 'targets' do
    it 'returns an array when given a string' do
      handler = described_class::Notifier.new('build:finished', id: build.id, config: 'https://outlook.office.com/webhook/test')
      expect(handler.targets).to eql ['https://outlook.office.com/webhook/test']
    end

    it 'returns an array when given an array in a hash' do
      expect(handler.targets).to eql ['https://outlook.office.com/webhook/test']
    end

    it 'parses comma separated string' do
      handler = described_class::Notifier.new('build:finished', id: build.id, config: { rooms: 'https://webhook1.com, https://webhook2.com' })
      expect(handler.targets).to eql ['https://webhook1.com', 'https://webhook2.com']
    end
  end
end
