describe Travis::Hub::Support::JobBoard do
  subject { described_class.new('http://jobbo.example.org') }

  let :request_stubs do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.delete '/jobs/3' do |*|
        [204, {}, '']
      end
    end
  end

  let(:client) do
    Faraday.new do |c|
      c.response :raise_error
      c.adapter :test, request_stubs
    end
  end
end
