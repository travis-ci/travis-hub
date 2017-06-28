describe Travis::Addons::Serializer::Tasks::Build do
  let(:owner)  { FactoryGirl.create(:user, login: 'login') }
  let(:repo)   { FactoryGirl.create(:repository) }
  let(:build)  { FactoryGirl.create(:build, owner: owner, repository: repo, pull_request: pull, tag: tag, jobs: [job]) }
  let(:job)    { FactoryGirl.create(:job, repository: repo) }
  let(:pull)   { FactoryGirl.create(:pull_request, number: 1, title: 'title') }
  let(:tag)    { FactoryGirl.create(:tag, name: 'v1.0.0') }
  let(:commit) { build.commit }
  let(:data)   { described_class.new(build).data }

  # base_commit: request.base_commit,
  # head_commit: request.head_commit,

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
      type: 'push'
    )
  end

  it 'owner data' do
    expect(data[:owner]).to eql(
      id: owner.id,
      type: 'User',
      login: 'login'
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
      slug: 'travis-ci/travis-core',
      url: 'https://github.com/travis-ci/travis-core'
    )
  end

  it 'request data' do
    expect(data[:request]).to eql(
      token: 'token',
      head_commit: nil
    )
  end

  it 'commit data' do
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

  it 'pull_request data' do
    expect(data[:pull_request]).to eql(
      number: 1,
      title: 'title'
    )
  end

  it 'tag data' do
    expect(data[:tag]).to eql(
      name: 'v1.0.0'
    )
  end

  it "doesn't include the source key" do
    build.config[:source_key] = '1234'
    expect(data[:build][:config]).to eql({})
  end
end
