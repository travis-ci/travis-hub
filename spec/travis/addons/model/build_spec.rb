describe Build do
  let(:build)  { FactoryGirl.create(:build, repository: repo, config: config) }
  let(:repo)   { FactoryGirl.create(:repository, key: repo_key) }
  let(:secure) { Travis::SecureConfig.new(repo.key) }

  def repo_key
    pair = OpenSSL::PKey::RSA.generate(1024)
    SslKey.new(public_key: pair.public_key.to_s, private_key: pair.to_pem)
  end

  def encrypt(string)
    secure.encrypt(string)
  end

  describe 'obfuscated_config' do
    subject { build.obfuscated_config }

    describe 'env vars given as strings' do
      let(:config) { { env: ['FOO=foo', 'BAR=bar'] } }
      it { should eq env: ['FOO=foo', 'BAR=bar'] }
    end

    describe 'env vars given as a hash' do
      let(:config) { { env: { FOO: 'foo', BAR: 'bar' } } }
      it { should eq env: ['FOO=foo BAR=bar'] }
    end

    describe 'env vars given as secure strs' do
      let(:config) { { env: [{ secure: encrypt('FOO=foo') }, { secure: encrypt('BAR=bar') }] } }
      it { should eq env: ['FOO=[secure]', 'BAR=[secure]'] }
    end

    describe 'env vars given as secure values' do
      let(:config) { { env: { FOO: { secure: encrypt('foo') }, BAR: { secure: encrypt('bar') } } } }
      it { should eq env: ['FOO=[secure] BAR=[secure]'] }
    end
  end
end
