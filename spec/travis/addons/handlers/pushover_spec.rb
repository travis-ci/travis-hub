describe Travis::Addons::Handlers::Pushover do
  let(:handler) { described_class::Notifier.new('build:finished', id: build.id, config: config) }
  let(:build)   { FactoryGirl.create(:build, state: :passed, config: { notifications: { pushover: config } }) }
  let(:config)  { { users: 'user', api_key: 'api_key' } }

  before { Travis::Event.setup([:pushover]) }

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
    let(:config) { [{ api_key: 'one', users: 'one' }, { api_key: 'two', users: 'two' }] }
    let(:jobs)   { Sidekiq::Queues.jobs_by_queue['pushover'] }
    let(:keys)   { jobs.map { |job| job['args'].last['api_key'] } }

    before { Travis::Event.dispatch('build:finished', id: build.id) }

    it { expect(jobs.size).to eq 2 }
    it { expect(keys).to eq ['one', 'two'] }
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

    it 'is true if users are present' do
      config[:users] = 'user'
      expect(handler.handle?).to eql(true)
    end

    it 'is false if no users are present' do
      config[:users] = []
      expect(handler.handle?).to eql(false)
    end

    it 'is true if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:pushover, :finished).returns(true)
      expect(handler.handle?).to eql(true)
    end

    it 'is false if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:pushover, :finished).returns(false)
      expect(handler.handle?).to eql(false)
    end
  end

  describe 'handle' do
    it 'enqueues a task' do
      handler.expects(:run_task).with(:pushover, is_a(Hash), users: ['user'], api_key: 'api_key', template: nil)
      handler.handle
    end
  end

  describe 'users' do
    let(:user)  { 'user' }
    let(:other) { 'other' }

    it 'returns an array of users when given a string' do
      config[:users] = user
      expect(handler.users).to eql [user]
    end

    it 'returns an array of user when given an array' do
      config[:users] = [user]
      expect(handler.users).to eql [user]
    end

    it 'returns an array of user when given a comma separated string' do
      config[:users] = "#{user}, #{other}"
      expect(handler.users).to eql [user, other]
    end
  end
end
