describe Travis::Addons::Handlers::Webhook do
  let(:handler) { described_class.new('build:finished', id: build.id) }
  let(:build)   { FactoryGirl.create(:build, state: :passed, config: { notifications: config }) }
  let(:config)  { { webhooks: { urls: 'http://host.com/target' } } }

  describe 'subscription' do
    before { Travis::Event.setup([:webhook]) }

    it 'build:started notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:started', id: build.id)
    end

    it 'build:finished notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:finished', id: build.id)
    end
  end

  describe 'handle?' do
    it 'is true if targets are present' do
      config[:webhooks] = { urls: 'http://host.com/target' }
      expect(handler.handle?).to eql(true)
    end

    it 'is false if no targets are present' do
      config[:webhooks] = false
      expect(handler.handle?).to eql(false)
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
      handler.expects(:run_task).with(is_a(Hash), targets: ['http://host.com/target'], token: 'token')
      handler.handle
    end
  end

  describe 'targets' do
    let(:target) { 'http://host.com/target' }
    let(:other)  { 'http://host.com/other' }

    it 'returns an array of targets when given a string' do
      config[:webhooks] = target
      expect(handler.targets).to eql [target]
    end

    it 'returns an array of targets when given an array' do
      config[:webhooks] = [target]
      expect(handler.targets).to eql [target]
    end

    it 'returns an array of targets when given a comma separated string' do
      config[:webhooks] = "#{target}, #{other}"
      expect(handler.targets).to eql [target, other]
    end

    it 'returns an array of targets given a string within a hash' do
      config[:webhooks] = { urls: target, on_success: 'change' }
      expect(handler.targets).to eql [target]
    end

    it 'returns an array of targets given an array within a hash' do
      config[:webhooks] = { urls: [target], on_success: 'change' }
      expect(handler.targets).to eql [target]
    end

    it 'returns an array of targets given a comma separated string within a hash' do
      config[:webhooks] = { urls: "#{target}, #{other}", on_success: 'change' }
      expect(handler.targets).to eql [target, other]
    end
  end
end
