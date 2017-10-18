describe Travis::Addons::Handlers::Discord do
  let(:handler) { described_class.new('build:finished', id: build.id) }
  let(:build)   { FactoryGirl.create(:build, state: :passed, config: { notifications: config }) }
  let(:config)  { { discord: 'channel' } }

  describe 'subscription' do
    before { Travis::Event.setup([:discord]) }

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
      config[:discord] = { channels: 'channel', on_pull_requests: false }
      build.update_attributes(event_type: 'pull_request')
      expect(handler.handle?).to eql(false)
    end

    it 'is true if channels are present' do
      config[:discord] = 'channel'
      expect(handler.handle?).to eql(true)
    end

    it 'is false if no channels are present' do
      config[:discord] = []
      expect(handler.handle?).to eql(false)
    end

    it 'is true if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:discord, :finished).returns(true)
      expect(handler.handle?).to eql(true)
    end

    it 'is false if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:discord, :finished).returns(false)
      expect(handler.handle?).to eql(false)
    end
  end

  describe 'handle' do
    it 'enqueues a task' do
      handler.expects(:run_task).with(:discord, is_a(Hash), targets: ['channel'])
      handler.handle
    end
  end

  describe 'targets' do
    let(:channel1)  { '12345:abc123-_' }
    let(:channel2) { '67890:cba321_-' }

    it 'returns an array of channels when given a string' do
      config[:discord] = channel1
      expect(handler.targets).to eql [channel1]
    end

    it 'returns an array of channels when given an array' do
      config[:discord] = [channel1]
      expect(handler.targets).to eql [channel1]
    end

    it 'returns an array of channels when given a comma separated string' do
      config[:discord] = "#{channel1}, #{channel2}"
      expect(handler.targets).to eql [channel1, channel2]
    end

    it 'returns an array of channels given a string within a hash' do
      config[:discord] = { channels: channel1, on_success: 'change' }
      expect(handler.targets).to eql [channel1]
    end

    it 'returns an array of channels given an array within a hash' do
      config[:discord] = { channels: [channel1], on_success: 'change' }
      expect(handler.targets).to eql [channel1]
    end

    it 'returns an array of channels given a comma separated string within a hash' do
      config[:discord] = { channels: "#{channel1}, #{channel2}", on_success: 'change' }
      expect(handler.targets).to eql [channel1, channel2]
    end
  end
end
