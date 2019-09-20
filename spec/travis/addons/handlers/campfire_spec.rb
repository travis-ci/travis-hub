describe Travis::Addons::Handlers::Campfire do
  let(:handler) { described_class.new('build:finished', id: build.id) }
  let(:build)   { FactoryGirl.create(:build, state: :passed, config: { notifications: config }) }
  let(:config)  { { campfire: 'room' } }

  describe 'subscription' do
    before { Travis::Event.setup([:campfire]) }

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

    it 'is false if the build is a pull request' do
      build.update_attributes(event_type: 'pull_request')
      expect(handler.handle?).to eql(false)
    end

    it 'is true if rooms are present' do
      config[:campfire] = 'room'
      expect(handler.handle?).to eql(true)
    end

    it 'is false if no rooms are present' do
      config[:campfire] = []
      expect(handler.handle?).to eql(false)
    end

    it 'is true if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:campfire, :finished).returns(true)
      expect(handler.handle?).to eql(true)
    end

    it 'is false if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:campfire, :finished).returns(false)
      expect(handler.handle?).to eql(false)
    end
  end

  describe 'handle' do
    it 'enqueues a task' do
      handler.expects(:run_task).with(:campfire, is_a(Hash), targets: ['room'])
      handler.handle
    end
  end

  describe 'targets' do
    let(:room)  { 'travis:apitoken@42' }
    let(:other) { 'evome:apitoken@44' }

    it 'returns an array of rooms when given a string' do
      config[:campfire] = room
      expect(handler.targets).to eql [[room]]
    end

    it 'returns an array of rooms when given an array' do
      config[:campfire] = [room]
      expect(handler.targets).to eql [[room]]
    end

    it 'returns an array of rooms when given a comma separated string' do
      config[:campfire] = "#{room}, #{other}"
      expect(handler.targets).to eql [[room, other]]
    end

    it 'returns an array of rooms given a string within a hash' do
      config[:campfire] = { rooms: room, on_success: 'change' }
      expect(handler.targets).to eql [[room]]
    end

    it 'returns an array of rooms given an array within a hash' do
      config[:campfire] = { rooms: [room], on_success: 'change' }
      expect(handler.targets).to eql [[room]]
    end

    it 'returns an array of rooms given a comma separated string within a hash' do
      config[:campfire] = { rooms: "#{room}, #{other}", on_success: 'change' }
      expect(handler.targets).to eql [[room, other]]
    end
  end
end
