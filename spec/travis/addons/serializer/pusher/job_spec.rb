describe Travis::Addons::Serializer::Pusher::Job do
  let(:repo)   { FactoryGirl.create(:repository) }
  let(:build)  { FactoryGirl.create(:build) }
  let(:job)    { FactoryGirl.create(:job, build: build, repository: repo) }
  let(:commit) { job.commit }
  let(:data)   { described_class.new(job).data }

  it 'data' do
    expect(data.except(:commit)).to eql(
      id: job.id,
      build_id: build.id,
      repository_id: repo.id,
      commit_id: commit.id,
      log_id: job.log_id,
      repository_slug: 'travis-ci/travis-core',
      repository_private: false,
      number: '1.1',
      started_at: nil,
      finished_at: nil,
      state: 'created',
      queue: nil,
      allow_failure: false
    )
  end

  it 'should return commit data' do
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
end
