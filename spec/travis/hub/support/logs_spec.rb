describe Travis::Hub::Support::Logs do
  subject { described_class.new(config) }

  let(:client) { mock('faraday') }
  let(:url) { 'http://loggo.example.com/' }
  let(:token) { 'fafafaf' }
  let(:config) { { url: url, token: token } }

  before do
    subject.instance_variable_set(:@client, client)
  end

  it 'puts a body' do
    client.expects(:put)
    expect(subject.update(1, msg: 'flee flah floof')).to be_nil
  end

  it 'appends a log part' do
    client.expects(:put)
    expect(subject.append_log_part(2, 'furble flume')).to eq nil
  end

  context 'when responses are not successful' do
    it 'does not put a body' do
      client.expects(:put).raises(StandardError)
      expect { subject.update(1, 'flaa flih fluuf') }
        .to raise_error(StandardError)
    end

    it 'does not append a log part' do
      client.expects(:put).raises(StandardError)
      expect { subject.append_log_part(3, 'foibled fable') }
        .to raise_error(StandardError)
    end
  end
end
