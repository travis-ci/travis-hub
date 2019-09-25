describe Travis::Addons::Handlers::Hipchat do
  let(:handler) { described_class::Notifier.new('build:finished', id: build.id, config: config) }
  let(:build)   { FactoryGirl.create(:build, state: :passed, config: { notifications: { hipchat: config } }) }
  let(:config)  { 'room' }

  before { Travis::Event.setup([:hipchat]) }

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
    let(:config)  { [{ rooms: 'one' }, { rooms: 'two' }] }
    let(:jobs)    { Sidekiq::Queues.jobs_by_queue['hipchat'] }
    let(:targets) { jobs.map { |job| job['args'].last['targets'] } }

    before { Travis::Event.dispatch('build:finished', id: build.id) }

    it { expect(jobs.size).to eq 2 }
    it { expect(targets).to eq [['one'], ['two']] }
  end

  describe 'given a plain string' do
    let(:params) { Sidekiq::Queues.jobs_by_queue['hipchat'][0]['args'].last }
    let(:config) { 'room' }

    before { Travis::Event.dispatch('build:finished', id: build.id) }

    it { expect(params['targets']).to eq ['room'] }
    it { expect(params['template']).to be_nil }
  end

  describe 'handle?' do
    it 'is true if the build is a push request' do
      build.update_attributes(event_type: 'push')
      expect(handler.handle?).to eql(true)
    end

    it 'is true by default if the build is a pull request' do
      build.update_attributes(event_type: 'pull_request')
      expect(handler.handle?).to eql(true)
    end

    describe 'is false if the build is a pull request and config opts out' do
      let(:config) { { rooms: 'room', on_pull_requests: false } }
      before { build.update_attributes(event_type: 'pull_request') }
      it { expect(handler.handle?).to eql(false) }
    end

    describe 'is true if rooms are present' do
      let(:config) { 'room' }
      it { expect(handler.handle?).to eql(true) }
    end

    describe 'is false if no rooms are present' do
      let(:config) { [] }
      it { expect(handler.handle?).to eql(false) }
    end

    it 'is true if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:hipchat, :finished).returns(true)
      expect(handler.handle?).to eql(true)
    end

    it 'is false if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:hipchat, :finished).returns(false)
      expect(handler.handle?).to eql(false)
    end
  end

  describe 'handle' do
    it 'enqueues a task' do
      handler.expects(:run_task).with(:hipchat, is_a(Hash), targets: ['room'], format: ['room'], template: nil)
      handler.handle
    end
  end

  describe 'targets' do
    let(:room)  { 'travis:apitoken@42' }
    let(:other) { 'evome:apitoken@44' }

    describe 'returns an array of rooms when given a string' do
      let(:config) { room }
      it { expect(handler.targets).to eql [room] }
    end

    describe 'returns an array of rooms when given an array' do
      let(:config) { [room] }
      it { expect(handler.targets).to eql [room] }
    end

    describe 'returns an array of rooms when given a comma separated string' do
      let(:config) { "#{room}, #{other}" }
      it { expect(handler.targets).to eql [room, other] }
    end

    describe 'returns an array of rooms given a string within a hash' do
      let(:config) { { rooms: room, on_success: 'change' } }
      it { expect(handler.targets).to eql [room] }
    end

    describe 'returns an array of rooms given an array within a hash' do
      let(:config) { { rooms: [room], on_success: 'change' } }
      it { expect(handler.targets).to eql [room] }
    end

    describe 'returns an array of rooms given a comma separated string within a hash' do
      let(:config) { { rooms: "#{room}, #{other}", on_success: 'change' } }
      it { expect(handler.targets).to eql [room, other] }
    end
  end
end
