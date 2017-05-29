describe Travis::Addons::Serializer::Generic::Build do
  let(:repo)   { FactoryGirl.create(:repository) }
  let(:build)  { FactoryGirl.create(:build, repository: repo, jobs: [job]) }
  let(:job)    { FactoryGirl.create(:job, repository: repo) }
  let(:commit) { build.commit }
  let(:data)   { described_class.new(build).data }

  it 'build data' do
    expect(data[:build]).to eql(
      id: build.id,
      repository_id: repo.id,
      commit_id: commit.id,
      job_ids: [job.id],
      number: '1',
      pull_request: false,
      pull_request_number: nil,
      config: {},
      state: 'created',
      previous_state: nil,
      started_at: nil,
      finished_at: nil,
      duration: nil,
      event_type: 'push'
    )
  end

  it 'repository data' do
    expect(data[:repository]).to eql(
      id: repo.id,
      key: nil,
      name: 'travis-core',
      owner_name: 'travis-ci',
      owner_avatar_url: nil,
      owner_email: nil,
      slug: 'travis-ci/travis-core'
    )
  end

  it 'includes the commit' do
    expect(data[:commit]).to eql(
      id: commit.id,
      sha: '62aae5f70ceee39123ef',
      branch: 'master',
      message: 'the commit message',
      committed_at: '2011-11-11T11:11:11Z',
      committer_name: 'Sven Fuchs',
      committer_email: 'me@svenfuchs.com',
      author_name: 'Sven Fuchs',
      author_email: 'me@svenfuchs.com',
      compare_url: 'https://github.com/travis-ci/travis-core/compare/master...develop',
    )
  end

  it "doesn't include the source key" do
    build.config[:source_key] = '1234'
    expect(data[:build][:config]).to eql({})
  end
end
