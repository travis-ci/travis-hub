describe Travis::Addons::Handlers::Scheduler do
  let(:job)     { FactoryGirl.create(:job) }
  let(:handler) { described_class.new('job:finished', id: job.id) }

  describe 'subscription' do
    before { Travis::Event.setup([:scheduler]) }

    # it 'job:create notifies' do
    #   described_class.expects(:notify).never
    #   Travis::Event.dispatch('job:create', id: job.id)
    # end

    it 'job:started does not notify' do
      described_class.expects(:notify).never
      Travis::Event.dispatch('job:started', id: job.id)
    end

    it 'job:finished notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('job:finished', id: job.id)
    end

    it 'job:restarted notifies' do
      described_class.expects(:notify).once
      Travis::Event.dispatch('job:restarted', id: job.id)
    end
  end

  describe 'handle?' do
    it 'is true' do
      expect(handler.handle?).to eql(true)
    end
  end

  describe 'handle' do
    it 'notifies scheduler' do
      ::Sidekiq::Client.expects(:push).with(
        'queue' => 'scheduler-2',
        'class' => 'Travis::Scheduler::Worker',
        'args'  => [:event, 'job:finished', id: job.id],
        'expires_in' => 2 * 3600
      )
      handler.handle
    end
  end
end
