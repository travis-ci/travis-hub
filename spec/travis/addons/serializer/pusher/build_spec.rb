describe Travis::Addons::Serializer::Pusher::Build do
  let(:repo)   { FactoryGirl.create(:repository) }
  let(:job)    { FactoryGirl.create(:job) }
  let(:build)  { FactoryGirl.create(:build, repository: repo, jobs: [job]) }
  let(:commit) { build.commit }
  let(:data)   { described_class.new(build).data }

  it 'build' do
    expect(data[:build].except(:matrix)).to eql(
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
      is_on_default_branch: true
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
      github_language: 'ruby'
    )
  end
end
