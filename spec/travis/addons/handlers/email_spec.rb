describe Travis::Addons::Handlers::Email do
  let(:handler) { described_class.new('build:finished', id: build.id) }
  let(:build)   { FactoryGirl.create(:build, commit: commit, config: { notifications: config }) }
  let(:commit)  { FactoryGirl.create(:commit, author_email: 'author@email.com', committer_email: 'committer@email.com') }
  let(:config)  { { email: email } }
  let(:email)   { 'me@email.com' }

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
    before { Email.create(email: email) }

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
      config[:email] = { recipients: 'me@email.com' }
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
    before { Email.create(email: email) }

    it 'enqueues a task' do
      handler.expects(:run_task).with(:email, is_a(Hash), recipients: ['me@email.com'], broadcasts: [])
      handler.handle
    end
  end

  describe 'recipients' do
    let(:email)     { 'me@email.com' }
    let(:other)     { 'other@email.com' }
    let(:author)    { 'author@email.com' }
    let(:committer) { 'committer@email.com' }

    describe 'no addresses given in config' do
      let(:config)  { { email: true } }

      it 'returns known committer and author addresses' do
        [committer, author].each { |email| Email.create(email: email) }
        expect(handler.recipients).to eql [committer, author]
      end

      it 'returns known author address' do
        Email.create(email: author)
        expect(handler.recipients).to eql [author]
      end

      it 'returns known committer address' do
        Email.create(email: committer)
        expect(handler.recipients).to eql [committer]
      end
    end

    it 'returns an array of addresses when given a string' do
      config[:email] = email
      expect(handler.recipients).to eql [email]
    end

    it 'returns an array of addresses when given an array' do
      config[:email] = [email]
      expect(handler.recipients).to eql [email]
    end

    it 'returns an array of addresses when given a comma separated string' do
      config[:email] = "#{email}, #{other}"
      expect(handler.recipients).to eql [email, other]
    end

    it 'returns an array of addresses given a string within a hash' do
      config[:email] = { recipients: email, on_success: 'change' }
      expect(handler.recipients).to eql [email]
    end

    it 'returns an array of addresses given an array within a hash' do
      config[:email] = { recipients: [email], on_success: 'change' }
      expect(handler.recipients).to eql [email]
    end

    it 'returns an array of addresses given a comma separated string within a hash' do
      config[:email] = { recipients: "#{email}, #{other}", on_success: 'change' }
      expect(handler.recipients).to eql [email, other]
    end
  end
end
