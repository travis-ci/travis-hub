describe Travis::Addons::Handlers::Email do
  let(:handler) { described_class::Notifier.new('build:finished', id: build.id, config: config) }
  let(:repo)    { FactoryGirl.create(:repository) }
  let(:build)   { FactoryGirl.create(:build, repository: repo, commit: commit, config: { notifications: { email: config } }) }
  let(:commit)  { FactoryGirl.create(:commit, author_email: 'author@email.com', committer_email: 'committer@email.com') }
  let!(:email)  { Email.create(email: address) }
  let(:config)  { address }
  let(:address) { 'me@email.com' }

  before { Travis::Event.setup([:email]) }

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
    let(:config) { [{ recipients: 'one@email.com' }, { recipients: 'two@email.com' }] }
    let(:jobs)   { Sidekiq::Queues.jobs_by_queue['email'] }
    let(:recipients) { jobs.map { |job| job['args'].last['recipients'] } }

    before { Travis::Event.dispatch('build:finished', id: build.id) }

    it { expect(jobs.size).to eq 2 }
    it { expect(recipients).to eq [['one@email.com'], ['two@email.com']] }
  end

  describe 'handle?' do
    context "when auto-canceling build" do
      let(:config) { { recipients: 'one@email.com', auto_canceled?: true } }
      let(:handler) { described_class::Notifier.new('build:canceled', id: build.id, config: config) }

      it 'is false if the build is auto-canceled' do
        build.update_attributes(event_type: 'push', state: 'canceled')
        expect(handler.handle?).to eql(false)
      end
    end

    context "when manually canceling build" do
      let(:config) { { recipients: 'one@email.com', auto_canceled?: false } }
      let(:handler) { described_class::Notifier.new('build:canceled', id: build.id, config: config) }

      it 'is true' do
        build.update_attributes(event_type: 'push', state: 'canceled')
        expect(handler.handle?).to eql(true)
      end
    end

    it 'is true if the build is a push request' do
      build.update_attributes(event_type: 'push')
      expect(handler.handle?).to eql(true)
    end

    it 'is false if the build is a pull request' do
      build.update_attributes(event_type: 'pull_request')
      expect(handler.handle?).to eql(false)
    end

    describe 'is false if no email config is present' do
      let(:config) { nil }
      it { expect(handler.handle?).to eql(false) }
    end

    describe 'is false if enabled is false' do
      let(:config) { { enabled: false, recipients: address } }
      it { expect(handler.handle?).to eql(false) }
    end

    describe 'is true if recipients are given in the config' do
      let(:config) { { recipients: address } }
      it { expect(handler.handle?).to eql(true) }
    end

    it 'is true if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:email, :finished).returns(true)
      expect(handler.handle?).to eql(true)
    end

    it 'is false if the config specifies so based on the build result' do
      Travis::Addons::Config.any_instance.stubs(:send_on?).with(:email, :finished).returns(false)
      expect(handler.handle?).to eql(false)
    end
  end

  describe 'handle' do
    let!(:broadcast) { Broadcast.create(message: 'message', category: 'announcement') }
    let(:recipient)  { 'me@email.com' }

    it 'enqueues a task' do
      handler.expects(:run_task).with(:email, is_a(Hash), recipients: [recipient], broadcasts: [{ message: 'message', category: 'announcement'}])
      handler.handle
    end
  end

  describe 'recipients' do
    let(:user)      { FactoryGirl.create(:user) }
    let(:user2)     { FactoryGirl.create(:user) }
    let(:address)   { 'me@email.com' }
    let(:other)     { 'other@email.com' }
    let(:author)    { 'author@email.com' }
    let(:committer) { 'committer@email.com' }

    describe 'no addresses given in config' do
      let(:config)  { true }
      before { repo.permissions.create(user: user) }

      it 'returns permitted and known committer and author addresses' do
        [committer, author].each { |address| Email.create(user: user, email: address) }
        expect(handler.recipients.sort).to eql [author, committer]
      end

      it 'returns permitted and known author address' do
        Email.create(user: user, email: author)
        expect(handler.recipients).to eql [author]
      end

      it 'returns permitted and known committer address' do
        Email.create(user: user, email: committer)
        expect(handler.recipients).to eql [committer]
      end

      it 'does not return users who have unsubscribed from this repo' do
        Email.create(user: user, email: committer)
        EmailUnsubscribe.create(user: user, repository: repo)
        expect(handler.recipients).to be_empty
      end

      it 'does not return users who have the no emails global preference' do
        user.update_attributes!(preferences: JSON.dump(build_emails: false))
        Email.create(user: user, email: committer)
        expect(handler.recipients).to be_empty
      end
    end

    describe 'returns an array of addresses when given a string' do
      let(:config) { address }
      it { expect(handler.recipients).to eql [address] }
    end

    describe 'returns an array of addresses when given an array' do
      let(:config) { [address] }
      it { expect(handler.recipients).to eql [address] }
    end

    describe 'returns an array of addresses when given a comma separated string' do
      let(:config) { "#{address}, #{other}" }
      it { expect(handler.recipients).to eql [address, other] }
    end

    describe 'returns an array of addresses given a string within a hash' do
      let(:config) { { recipients: address, on_success: 'change' } }
      it { expect(handler.recipients).to eql [address] }
    end

    describe 'returns an array of addresses given an array within a hash' do
      let(:config) { { recipients: [address], on_success: 'change' } }
      it { expect(handler.recipients).to eql [address] }
    end

    describe 'returns an array of addresses given a comma separated string within a hash' do
      let(:config) { { recipients: "#{address}, #{other}", on_success: 'change' } }
      it { expect(handler.recipients).to eql [address, other] }
    end

    describe 'filters out unsubscribed users' do
      let(:config) { address }

      before {
        Email.create(user: user, email: address)
        Email.create(user: user2, email: other)
        EmailUnsubscribe.create(user: user2, repository: repo)
      }

      it {
        expect(handler.recipients).to eql [address]
      }
    end

    describe 'observes user-level no emails preference' do
      let(:config) { address }
      before { Email.create(user: user, email: address) }
      before { user.update_attributes!(preferences: JSON.dump(build_emails: false)) }
      it { expect(handler.recipients).to be_empty }
    end
  end
end
