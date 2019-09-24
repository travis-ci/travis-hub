describe Travis::Addons::Handlers::Irc do
  let(:handler) { described_class::Notifier.new('build:finished', id: build.id, config: config) }
  let(:build)   { FactoryGirl.create(:build, state: :passed, config: { notifications: { irc: config } }) }
  let(:config)  { 'channel' }

  describe 'subscription' do
    before { Travis::Event.setup([:irc]) }

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

    describe 'is true if channels are present' do
      let(:config) { 'channel' }
      it { expect(handler.handle?).to eql(true) }
    end

    describe 'is false if no channels are present' do
      let(:config) { [] }
      it { expect(handler.handle?).to eql(false) }
    end

    it 'is true if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:irc, :finished).returns(true)
      expect(handler.handle?).to eql(true)
    end

    it 'is false if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:irc, :finished).returns(false)
      expect(handler.handle?).to eql(false)
    end
  end

  describe 'handle' do
    it 'enqueues a task' do
      handler.expects(:run_task).with(:irc, is_a(Hash), channels: ['channel'], template: ['channel'])
      handler.handle
    end
  end

  describe 'channels' do
    let(:channel) { 'travis@freenode' }
    let(:other)   { 'evome@freenode' }

    describe 'returns an array of channels when given a string' do
      let(:config) { channel }
      it { expect(handler.channels).to eql [channel] }
    end

    describe 'returns an array of channels when given an array' do
      let(:config) { [channel] }
      it { expect(handler.channels).to eql [channel] }
    end

    describe 'returns an array of channels when given a comma separated string' do
      let(:config) { "#{channel}, #{other}" }
      it { expect(handler.channels).to eql [channel, other] }
    end

    describe 'returns an array of channels given a string within a hash' do
      let(:config) { { channels: channel, on_success: 'change' } }
      it { expect(handler.channels).to eql [channel] }
    end

    describe 'returns an array of channels given an array within a hash' do
      let(:config) { { channels: [channel], on_success: 'change' } }
      it { expect(handler.channels).to eql [channel] }
    end

    describe 'returns an array of channels given a comma separated string within a hash' do
      let(:config) { { channels: "#{channel}, #{other}", on_success: 'change' } }
      it { expect(handler.channels).to eql [channel, other] }
    end
  end
end
