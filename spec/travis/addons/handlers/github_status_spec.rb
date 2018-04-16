describe Travis::Addons::Handlers::GithubStatus do
  let(:handler)     { described_class.new('build:finished', id: build.id) }
  let(:build)       { FactoryGirl.create(:build, repository: repository) }
  let(:permissions) { build.repository.permissions }
  let(:repository)  { FactoryGirl.create(:repository) }
  let(:admin)       { FactoryGirl.create(:user, login: 'admin', github_oauth_token: 'admin-token') }
  let(:committer)   { FactoryGirl.create(:user, login: 'committer', github_oauth_token: 'committer-token', email: 'committer@email.com', installation: nil) }
  let(:user)        { FactoryGirl.create(:user, login: 'user', github_oauth_token: 'user-token', installation: nil) }
  let(:gh_apps_installation) { FactoryGirl.create(:installation) }

  describe 'subscription' do
    before { Travis::Event.setup([:github_status]) }

    it 'build:created notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:created', id: build.id)
    end

    it 'build:started notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:started', id: build.id)
    end

    it 'build:finished notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:finished', id: build.id)
    end

    it 'build:canceled notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:canceled', id: build.id)
    end
  end

  describe 'handle?' do
    it 'is false if no tokens can be found' do
      expect(handler.handle?).to eql(false)
    end

    it 'is true if a token can be found' do
      permissions.create(user: admin, admin: true)
      expect(handler.handle?).to eql(true)
    end

    context "when repo is managed by GitHub Apps" do
      before do
        admin.update_attributes(installation: gh_apps_installation)
        build.repository.update_attributes(
          owner: admin,
          managed_by_installation_at: Time.now
        )
      end

      it 'is true' do
        expect(handler.handle?).to eql true
      end
    end
  end

  describe 'handle' do
    context "when there is an admion on the repo" do
      before { permissions.create(user: admin, admin: true) }

      it 'enqueues a task' do
        handler.expects(:run_task).with(:github_status, is_a(Hash), tokens: { 'admin' => 'admin-token' })
        handler.handle
      end
    end

    context "when repo is managed by GitHub Apps" do
      before do
        admin.update_attributes(installation: gh_apps_installation)
        build.repository.update_attributes(
          owner: admin,
          managed_by_installation_at: Time.now
        )
        handler.handle?
      end
      it 'enqueues a task' do
        handler.expects(:run_task).with(:github_status, is_a(Hash), tokens: {})
        handler.handle
      end
    end
  end

  describe 'tokens' do
    let(:tokens) { handler.send(:tokens) }

    before do
      build.commit.update_attributes!(committer_email: 'committer@email.com')
      Email.create(user: committer, email: 'committer@email.com')
      permissions.create(user: user, push: true)
      permissions.create(user: admin, admin: true)
      permissions.create(user: committer, push: true)
    end

    it 'prioritizes a known committer token over admin tokens' do
      expect(tokens.keys.index('committer')).to be < tokens.keys.index('admin')
    end

    it 'prioritizes a admin tokens over (push) user tokens' do
      expect(tokens.keys.index('admin')).to be < tokens.keys.index('user')
    end

    it 'includes a known committer token, admin tokens, and (push) user tokens' do
      expect(tokens).to eq('committer' => 'committer-token', 'admin' => 'admin-token', 'user' => 'user-token')
    end
  end
end
