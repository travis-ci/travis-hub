describe Travis::Addons::Serializer::Pusher::Job do
  let(:repo)   { FactoryGirl.create(:repository) }
  let(:job)    { FactoryGirl.create(:job, repository: repo, build: build, commit: commit, stage: stage) }
  let(:commit) { FactoryGirl.create(:commit) }
  let(:build)  { FactoryGirl.create(:build) }
  let(:stage)  { FactoryGirl.create(:stage, build: build, number: 1, name: 'test', state: :created) }
  let(:data)   { described_class.new(job).data }

  it 'data' do
    expect(data.except(:commit, :stage)).to eql(
      id: job.id,
      build_id: build.id,
      repository_id: repo.id,
      commit_id: commit.id,
      repository_slug: 'travis-ci/travis-core',
      repository_private: false,
      number: '1.1',
      started_at: nil,
      finished_at: nil,
      state: 'created',
      queue: nil,
      allow_failure: false,
      updated_at: build.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')
    )
  end

  it 'includes commit data' do
    expect(data[:commit]).to eql(
      id: commit.id,
      sha: '62aae5f70ceee39123ef',
      branch: 'master',
      message: 'the commit message',
      committed_at: '2011-11-11T11:11:11Z',
      committer_email: 'me@svenfuchs.com',
      committer_name: 'Sven Fuchs',
      author_name: 'Sven Fuchs',
      author_email: 'me@svenfuchs.com',
      compare_url: 'https://github.com/travis-ci/travis-core/compare/master...develop',
    )
  end

  it 'includes commit data' do
    expect(data[:stage]).to eql(
      id: stage.id,
      build_id: stage.build.id,
      number: 1,
      name: 'test',
      state: :created,
      started_at: nil,
      finished_at: nil
    )
  end
end
