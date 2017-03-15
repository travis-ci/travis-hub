describe Travis::Hub::Support::Logs do
  subject { described_class.new(config) }

  let :request_stubs do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.put '/logs/1' do |env|
        [200, {}, '{}']
      end

      stub.put '/log-parts/2/last' do |env|
        [200, {}, '{}']
      end

      stub.put '/logs/4' do |env|
        [404, {}, '{}']
      end

      stub.put '/log-parts/3/last' do |env|
        [404, {}, '{}']
      end
    end
  end

  let(:client) do
    Faraday.new do |c|
      c.response :raise_error
      c.adapter :test, request_stubs
    end
  end

  let(:url) { 'http://loggo.example.com/' }
  let(:token) { 'fafafaf' }
  let(:config) { { url: url, token: token } }

  before do
    subject.instance_variable_set(:@client, client)
  end

  it 'puts a body' do
    expect(subject.update(1, msg: 'flee flah floof')).to be_success
  end

  it 'appends a log part' do
    expect(subject.append_log_part(2, 'furble flume')).to be_success
  end

  context 'when responses are not successful' do
    it 'does not put a body' do
      expect { subject.update(4, 'flaa flih fluuf') }
        .to raise_error(StandardError)
    end

    it 'does not append a log part' do
      expect { subject.append_log_part(3, 'foibled fable') }
        .to raise_error(StandardError)
    end
  end
end
