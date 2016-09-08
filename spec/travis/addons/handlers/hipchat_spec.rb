describe Travis::Addons::Handlers::Hipchat do
  let(:handler) { described_class.new('build:finished', id: build.id) }
  let(:build)   { FactoryGirl.create(:build, state: :passed, config: { notifications: config }) }
  let(:config)  { { hipchat: 'room' } }

  describe 'subscription' do
    before { Travis::Event.setup([:hipchat]) }

    it 'build:started does not notify' do
      described_class.expects(:notify).never
      Travis::Event.dispatch('build:started', id: build.id)
    end

    it 'build:finished notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:finished', id: build.id)
    end
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

    it 'is false if the build is a pull request and config opts out' do
      config[:hipchat] = { rooms: 'room', on_pull_requests: false }
      build.update_attributes(event_type: 'pull_request')
      expect(handler.handle?).to eql(false)
    end

    it 'is true if rooms are present' do
      config[:hipchat] = 'room'
      expect(handler.handle?).to eql(true)
    end

    it 'is false if no rooms are present' do
      config[:hipchat] = []
      expect(handler.handle?).to eql(false)
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
      handler.expects(:run_task).with(is_a(Hash), targets: ['room'])
      handler.handle
    end
  end

  describe 'targets' do
    let(:room)  { 'travis:apitoken@42' }
    let(:other) { 'evome:apitoken@44' }

    it 'returns an array of rooms when given a string' do
      config[:hipchat] = room
      expect(handler.targets).to eql [room]
    end

    it 'returns an array of rooms when given an array' do
      config[:hipchat] = [room]
      expect(handler.targets).to eql [room]
    end

    it 'returns an array of rooms when given a comma separated string' do
      config[:hipchat] = "#{room}, #{other}"
      expect(handler.targets).to eql [room, other]
    end

    it 'returns an array of rooms given a string within a hash' do
      config[:hipchat] = { rooms: room, on_success: 'change' }
      expect(handler.targets).to eql [room]
    end

    it 'returns an array of rooms given an array within a hash' do
      config[:hipchat] = { rooms: [room], on_success: 'change' }
      expect(handler.targets).to eql [room]
    end

    it 'returns an array of rooms given a comma separated string within a hash' do
      config[:hipchat] = { rooms: "#{room}, #{other}", on_success: 'change' }
      expect(handler.targets).to eql [room, other]
    end
  end
end
