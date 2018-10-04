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
    before do 
      build.repository.update_attributes(owner: admin)
    end

    context 'when repo is not managed by GitHub Apps' do
      it 'is false if a token can be found' do
        permissions.create(user: admin, admin: true)
        expect(handler.handle?).to eql(true)
      end

      it 'is false if no tokens can be found' do
        expect(handler.handle?).to eql(false)
      end
    end

    context 'when a repo is managed by GitHub Apps' do
      before do
        admin.update_attributes(installation: gh_apps_installation)
        build.repository.update_attributes(
          managed_by_installation_at: Time.now
        )
      end

      it 'is false if a token cannot be found' do
        expect(handler.handle?).to eql(false)
      end

      it 'is false if a token can be found' do
        permissions.create(user: admin, admin: true)
        expect(handler.handle?).to eql(false)
      end

      it 'is false if a repo flag use_commit_status doesn"t exist' do
        expect(handler.handle?).to eql(false)
      end
      
      it 'is false if repo flag use_commit_status is false' do 
        Travis::Features.deactivate_repository(:use_commit_status, repository.id)
        expect(handler.handle?).to eql(false)
      end

      it 'is false if the owner flag use_commit_status is false' do 
        Travis::Features.deactivate_repository(:use_commit_status, repository.owner)
        expect(handler.handle?).to eql(false)
      end

      it 'is false if both owner and repo flag use_commit_status is false' do
        Travis::Features.deactivate_repository(:use_commit_status, repository.id)
        Travis::Features.deactivate_repository(:use_commit_status, repository.owner)
        expect(handler.handle?).to eql(false)
      end

      it 'is false if use_commit_status is disabled globally' do
        Travis::Features.disable_for_all(:use_commit_status)
        expect(handler.handle?).to eql(false)
      end
    end

    context 'when a repo is managed by GitHub Apps' do
      before do
        admin.update_attributes(installation: gh_apps_installation)
        build.repository.update_attributes(
          managed_by_installation_at: Time.now
        )
      end
      
      it 'is true if repo flag use_commit_status is true' do 
        Travis::Features.activate_repository(:use_commit_status, repository.id)
        expect(handler.handle?).to eql(true)
      end

      after do
        Travis::Features.deactivate_repository(:use_commit_status, repository.id)
      end

      it 'is true if the owner flag use_commit_status is true' do 
        Travis::Features.activate_owner(:use_commit_status, repository.owner)
        expect(handler.handle?).to eql(true)
      end

      after do
        Travis::Features.deactivate_owner(:use_commit_status, repository.owner)
      end

      it 'is true if both owner and repo flag use_commit_status is true' do
        Travis::Features.activate_repository(:use_commit_status, repository.id)
        Travis::Features.activate_repository(:use_commit_status, repository.owner)
        expect(handler.handle?).to eql(true)
      end

      after do 
        Travis::Features.deactivate_repository(:use_commit_status, repository.id)
        Travis::Features.deactivate_owner(:use_commit_status, repository.owner)
      end 

      it 'is true if the use_commit_status feature flag is enabled globally' do 
        Travis::Features.enable_for_all(:use_commit_status)
        expect(handler.handle?).to eql(true)
      end 

      after do
        Travis::Features.disable_for_all(:use_commit_status)
      end
    end
  end

  describe 'handle' do
    before { permissions.create(user: admin, admin: true) }

    it 'enqueues a task' do
      handler.expects(:run_task).with(:github_status, is_a(Hash), tokens: { 'admin' => 'admin-token' }, installation: nil)
      handler.handle
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

  describe 'installation' do
    let(:installation) { handler.send(:installation) }

    before do
      gh_apps_installation.update(owner: repository.owner, removed_by_id: nil)
    end

    it 'includes the installation id' do
      handler.expects(:run_task).with(
        :github_status, is_a(Hash),
        tokens: {},
        installation: gh_apps_installation.github_id
      )
      handler.handle
    end
  end
end
