describe Travis::Addons::Handlers::StatesCache do
  let(:repo)    { FactoryGirl.create(:repository) }
  let(:build)   { FactoryGirl.create(:build, state: 'failed', repository: repo) }
  let(:handler) { described_class.new('build:finished', id: build.id) }
  let(:cache)   { described_class.states_cache }

  before { Travis::Event.setup([:states_cache]) }

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

  describe 'handle?' do
    it 'is true if the build is a push request' do
      build.update_attributes(event_type: 'push')
      expect(handler.handle?).to eql(true)
    end

    it 'is false if the build is a pull request' do
      build.update_attributes(event_type: 'pull_request')
      expect(handler.handle?).to eql(false)
    end
  end

  describe 'handler' do
    it 'build:finished updates the cache' do
      data = { 'id' => build.id, 'state' => :failed }
      cache.expects(:write).with(build.repository_id, 'master', data)
      Travis::Event.dispatch('build:finished', id: build.id)
    end
  end
end
