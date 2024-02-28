describe Travis::Addons::Handlers::GithubCheckStatus do
  let(:handler)     { described_class.new('build:finished', id: build.id) }
  let(:build)       { FactoryBot.create(:build, repository:) }
  let(:permissions) { build.repository.permissions }
  let(:repository)  { FactoryBot.create(:repository) }
  let(:admin)       { FactoryBot.create(:user, login: 'admin', github_oauth_token: 'admin-token') }
  let(:committer)   { FactoryBot.create(:user, login: 'committer', github_oauth_token: 'committer-token', email: 'committer@email.com', installation: nil) }
  let(:user)        { FactoryBot.create(:user, login: 'user', github_oauth_token: 'user-token', installation: nil) }
  let(:gh_apps_installation) { FactoryBot.create(:installation) }

  describe 'handle?' do
    context 'when repo is managed by GitHub Apps' do
      before do
        admin.update(installation: gh_apps_installation)
        build.repository.update(
          owner: admin,
          managed_by_installation_at: Time.now
        )
      end

      it 'is true' do
        expect(handler.handle?).to eql true
      end
    end

    context 'when a repo is not managed by GitHub Apps' do
      before do
        admin.update(installation: gh_apps_installation)
        build.repository.update(
          owner: admin,
          managed_by_installation_at: nil
        )
      end

      it 'is false' do
        expect(handler.handle?).to eql false
      end
    end
  end

  describe 'handle' do
    context 'when repo is managed by GitHub Apps' do
      before do
        admin.update(installation: gh_apps_installation)
        build.repository.update(
          owner: admin,
          managed_by_installation_at: Time.now
        )
        handler.handle?
      end

      it 'enqueues a task' do
        handler.expects(:run_task).with(:github_check_status, is_a(Hash), installation: 1)
        handler.handle
      end
    end
  end
end
