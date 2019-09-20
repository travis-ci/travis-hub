describe Travis::Addons::Handlers::Email do
  let(:handler) { described_class.new('build:finished', id: build.id) }
  let(:repo)    { FactoryGirl.create(:repository) }
  let(:build)   { FactoryGirl.create(:build, repository: repo, commit: commit, config: { notifications: config }) }
  let(:commit)  { FactoryGirl.create(:commit, author_email: 'author@email.com', committer_email: 'committer@email.com') }
  let!(:email)  { Email.create(email: address) }
  let(:config)  { { email: address } }
  let(:address) { 'me@email.com' }

  describe 'subscription' do
    before { Travis::Event.setup([:email]) }

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

    it 'is false if no email config is present' do
      config[:email] = nil
      expect(handler.handle?).to eql(false)
    end

    it 'is true if recipients are given in the config' do
      config[:email] = { recipients: address }
      expect(handler.handle?).to eql(true)
    end

    it 'is false if email config is not present' do
      config[:email] = nil
      expect(handler.handle?).to eql(false)
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

    context "when 2 email notifications are configured" do
      let(:config) {
        [
          {email: address},
          {email: ["joe@example.com"]},
        ]
      }

      it 'enqueues 2 distinct email tasks' do
        handler.expects(:run_task).with(:email, is_a(Hash), recipients: [address], broadcasts: [{ message: 'message', category: 'announcement'}])
        handler.expects(:run_task).with(:email, is_a(Hash), recipients: ["joe@example.com"], broadcasts: [{ message: 'message', category: 'announcement'}])
        handler.handle
      end
    end
  end

  describe 'recipients' do
    let(:user)      { FactoryGirl.create(:user) }
    let(:address)   { 'me@email.com' }
    let(:other)     { 'other@email.com' }
    let(:author)    { 'author@email.com' }
    let(:committer) { 'committer@email.com' }

    describe 'no addresses given in config' do
      let(:config)  { { email: true } }
      before { repo.permissions.create(user: user) }

      it 'returns permitted and known committer and author addresses' do
        [committer, author].each { |address| Email.create(user: user, email: address) }
        expect(handler.recipients(config).sort).to eql [author, committer]
      end

      it 'returns permitted and known author address' do
        Email.create(user: user, email: author)
        expect(handler.recipients(config)).to eql [author]
      end

      it 'returns permitted and known committer address' do
        Email.create(user: user, email: committer)
        expect(handler.recipients(config)).to eql [committer]
      end

      it 'does not return users who have unsubscribed from this repo' do
        Email.create(user: user, email: committer)
        EmailUnsubscribe.create(user: user, repository: repo)
        expect(handler.recipients(config)).to be_empty
      end

      it 'does not return users who have the no emails global preference' do
        user.update_attributes!(preferences: JSON.dump(build_emails: false))
        Email.create(user: user, email: committer)
        expect(handler.recipients(config)).to be_empty
      end
    end

    it 'returns an array of addresses when given a string' do
      config[:email] = address
      expect(handler.recipients(config)).to eql [address]
    end

    it 'returns an array of addresses when given an array' do
      config[:email] = [address]
      expect(handler.recipients(config)).to eql [address]
    end

    it 'returns an array of addresses when given a comma separated string' do
      config[:email] = "#{address}, #{other}"
      expect(handler.recipients(config)).to eql [address, other]
    end

    it 'returns an array of addresses given a string within a hash' do
      config[:email] = { recipients: address, on_success: 'change' }
      expect(handler.recipients(config)).to eql [address]
    end

    it 'returns an array of addresses given an array within a hash' do
      config[:email] = { recipients: [address], on_success: 'change' }
      expect(handler.recipients(config)).to eql [address]
    end

    it 'returns an array of addresses given a comma separated string within a hash' do
      config[:email] = { recipients: "#{address}, #{other}", on_success: 'change' }
      expect(handler.recipients(config)).to eql [address, other]
    end

    it 'ignores repo-level unsubscribe' do
      config[:email] = address
      Email.create(user: user, email: address)
      EmailUnsubscribe.create(user: user, repository: repo)

      expect(handler.recipients(config)).to eql [address]
    end

    it 'observes user-level no emails preference' do
      config[:email] = address
      Email.create(user: user, email: address)
      user.update_attributes!(preferences: JSON.dump(build_emails: false))

      expect(handler.recipients(config)).to be_empty
    end
  end
end
