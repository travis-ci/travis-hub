describe Travis::Addons::Handlers::Keenio do
  let(:build) { FactoryGirl.create(:build) }
  let(:job)   { FactoryGirl.create(:job, owner: owner) }
  let(:owner) { FactoryGirl.create(:user) }

  describe 'subscription' do
    before { Travis::Event.setup([:keenio]) }

    it 'job:started notifies' do
      described_class.expects(:notify).never
      Travis::Event.dispatch('job:started', id: job.id)
    end

    it 'job:finished notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('job:finished', id: job.id)
    end

    it 'build:started notifies' do
      described_class.expects(:notify).never
      Travis::Event.dispatch('build:started', id: build.id)
    end

    it 'build:finished notifies' do
      described_class.expects(:notify).never
      Travis::Event.dispatch('build:finished', id: build.id)
    end
  end

  describe 'handle' do
    let(:handler) { described_class.new('job:finished', id: job.id) }

    it 'publishes to keen' do
      Keen.expects(:publish_batch)
      handler.handle
    end
  end
end
