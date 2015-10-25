describe Travis::Addons::Serializer::Webhook::Build do
  let(:repo)    { FactoryGirl.create(:repository) }
  let(:job)     { FactoryGirl.create(:job, repository: repo) }
  let(:build)   { FactoryGirl.create(:build, repository: repo, jobs: [job]) }
  let(:commit)  { build.commit }
  let(:request) { build.request }
  let(:data)    { described_class.new(build).data }

  it 'data' do
    expect(data.except(:repository, :matrix)).to eql(
      id: build.id,
      number: '1',
      status: nil,
      result: nil,
      status_message: 'Pending',
      result_message: 'Pending',
      started_at: nil,
      finished_at: nil,
      duration: nil,
      build_url: "https://host.com/travis-ci/travis-core/builds/#{build.id}",
      config:  {},
      commit_id: commit.id,
      commit: '62aae5f70ceee39123ef',
      base_commit: request.base_commit,
      head_commit: request.head_commit,
      branch: 'master',
      compare_url: 'https://github.com/travis-ci/travis-core/compare/master...develop',
      message: 'the commit message',
      committed_at: '2011-11-11T11:11:11Z',
      committer_name: 'Sven Fuchs',
      committer_email: 'me@svenfuchs.com',
      author_name: 'Sven Fuchs',
      author_email: 'me@svenfuchs.com',
      type: 'push',
      state: 'created',
      pull_request: false,
      pull_request_number: build.pull_request_number,
      pull_request_title: build.pull_request_title,
      tag: commit.tag_name
    )
  end

  it 'repository' do
    expect(data[:repository]).to eql(
      id: repo.id,
      name: 'travis-core',
      owner_name: 'travis-ci',
      url: nil
    )
  end

  describe 'includes the build matrix' do
    it 'payload' do
      expect(data[:matrix].first).to eql(
        id: job.id,
        repository_id: repo.id,
        parent_id: build.id,
        number: '1.1',
        state: 'created',
        started_at: nil,
        finished_at: nil,
        config: {},
        status: nil,
        result: nil,
        commit: '62aae5f70ceee39123ef',
        branch: 'master',
        message: 'the commit message',
        author_name: 'Sven Fuchs',
        author_email: 'me@svenfuchs.com',
        committer_name: 'Sven Fuchs',
        committer_email: 'me@svenfuchs.com',
        committed_at: '2011-11-11T11:11:11Z',
        compare_url: 'https://github.com/travis-ci/travis-core/compare/master...develop',
        allow_failure: false
      )
    end
  end

  describe 'obfuscates config' do
    let(:var) { build.repository.key.secure.encrypt('BAR=bar') }

    before do
      build.repository.key = SslKey.new
      generate_keys(build.repository.key)
    end

    def generate_keys(key)
      pair = OpenSSL::PKey::RSA.generate(1024)
      key.public_key  = pair.public_key.to_s
      key.private_key = pair.to_pem
    end

    it 'on build' do
      build.update_attributes!(config: { env: var })
      expect(data[:config]).to eql(env: ['BAR=[secure]'])
    end

    it 'on job' do
      job.update_attributes!(config: { env: var })
      expect(data[:matrix][0][:config]).to eql(env: ['BAR=[secure]'])
    end

    it 'removes the source key' do
      build.update_attributes!(config: { source_key: 'source_key' })
      expect(data[:config]).to eql({})
    end
  end
end
