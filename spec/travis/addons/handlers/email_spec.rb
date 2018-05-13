describe Travis::Addons::Handlers::Email do
  let(:handler) { described_class.new('build:finished', id: build.id) }
  let(:repo)    { FactoryGirl.create(:repository) }
  let(:build)   { FactoryGirl.create(:build, repository: repo, config: { notifications: config }) }
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
    let!(:broadcast) { Broadcast.create(message: 'message') }
    let(:recipient)  { 'me@email.com' }

    it 'enqueues a task' do
      handler.expects(:run_task).with(:email, is_a(Hash), recipients: [recipient], broadcasts: [{ message: 'message' }])
      handler.handle
    end
  end

  describe 'recipients' do
    let(:user)    { FactoryGirl.create(:user, first_logged_in_at: Time.now, email: "josh@travis-ci.com") }
    let(:address) { 'me@email.com' }
    let(:other)   { 'other@email.com' }

    describe 'no addresses given in config' do
      let(:config)  { { email: true } }
      before { build.sender = user }

      describe 'creator is not a user' do
        before { build.sender = nil }
        it 'returns no email address' do
          expect(handler.recipients.sort).to eql nil
        end
      end

      describe 'creator has not signed in' do
        before { user.first_logged_in_at = nil }
        it 'returns no email address' do
          expect(handler.recipients.sort).to eql nil
        end
      end

      describe 'creator does not have an email address in the system' do
        before { user.email = nil }
        it 'returns no email address' do
          expect(handler.recipients.sort).to eql nil
        end
      end

      describe 'creator has a email address in the system' do
        it 'returns the creators email address' do
          expect(handler.recipients.sort).to eql [user.email]
        end
      end
    end

    it 'returns an array of addresses when given a string' do
      config[:email] = address
      expect(handler.recipients).to eql [address]
    end

    it 'returns an array of addresses when given an array' do
      config[:email] = [address]
      expect(handler.recipients).to eql [address]
    end

    it 'returns an array of addresses when given a comma separated string' do
      config[:email] = "#{address}, #{other}"
      expect(handler.recipients).to eql [address, other]
    end

    it 'returns an array of addresses given a string within a hash' do
      config[:email] = { recipients: address, on_success: 'change' }
      expect(handler.recipients).to eql [address]
    end

    it 'returns an array of addresses given an array within a hash' do
      config[:email] = { recipients: [address], on_success: 'change' }
      expect(handler.recipients).to eql [address]
    end

    it 'returns an array of addresses given a comma separated string within a hash' do
      config[:email] = { recipients: "#{address}, #{other}", on_success: 'change' }
      expect(handler.recipients).to eql [address, other]
    end
  end
end
