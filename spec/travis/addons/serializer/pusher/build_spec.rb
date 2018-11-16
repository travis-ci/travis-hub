describe Travis::Addons::Serializer::Pusher::Build do
  let(:repo)   { FactoryGirl.create(:repository, active: true) }
  let(:job)    { FactoryGirl.create(:job) }
  let(:user)   { FactoryGirl.create(:user, login: 'svenfuchs', name: 'Sven Fuchs', avatar_url: 'https://avatars2.githubusercontent.com/u/2208') }
  let(:build)  { FactoryGirl.create(:build, repository: repo, stages: [stage], jobs: [job], sender: user) }
  let(:stage)  { FactoryGirl.create(:stage, jobs: [job], number: 1, name: 'test') }
  let!(:branch){ FactoryGirl.create(:branch, repository: repo, name: 'master', last_build: build) }
  let(:commit) { build.commit }
  let(:data)   { described_class.new(build).data }

  before { repo.update_attribute(:current_build_id, build.id) }

  it 'build' do
    expect(data[:build].except(:matrix, :stages)).to eql(
      id: build.id,
      repository_id: build.repository_id,
      number: '1',
      state: 'created',
      started_at: nil,
      finished_at: nil,
      duration: nil,
      commit: '62aae5f70ceee39123ef',
      commit_id: commit.id,
      branch: 'master',
      message: 'the commit message',
      author_name: 'Sven Fuchs',
      author_email: 'me@svenfuchs.com',
      committer_name: 'Sven Fuchs',
      committer_email: 'me@svenfuchs.com',
      committed_at: '2011-11-11T11:11:11Z',
      compare_url: 'https://github.com/travis-ci/travis-core/compare/master...develop',
      event_type: 'push',
      pull_request: false,
      pull_request_title: nil,
      pull_request_number: nil,
      job_ids: [job.id],
      updated_at: build.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'),
      created_by: {
        id: user.id,
        login: 'svenfuchs',
        name: 'Sven Fuchs',
        avatar_url: 'https://avatars2.githubusercontent.com/u/2208'
      }
    )
  end

  it 'repository' do
    expect(data[:repository]).to eql(
      id: build.repository_id,
      slug: 'travis-ci/travis-core',
      private: false,
      description: 'the repo description',
      last_build_id: nil,
      last_build_number: nil,
      last_build_started_at: nil,
      last_build_finished_at: nil,
      last_build_duration: nil,
      last_build_state: '',
      last_build_language: nil,
      github_language: 'ruby',
      default_branch: {
        name: 'master',
        last_build_id: build.id
      },
      active: true,
      current_build_id: build.id
    )
  end

  it 'stages' do
    expect(data[:stages]).to eql(
      [
        id: stage.id,
        build_id: stage.build.id,
        number: 1,
        name: 'test',
        state: :created,
        started_at: nil,
        finished_at: nil
      ]
    )
  end
end
