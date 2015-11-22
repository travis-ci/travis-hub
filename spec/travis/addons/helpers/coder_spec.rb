describe Travis::Addons::Helpers::Coder do
  let(:klass)  { Class.new { include Travis::Addons::Helpers::Coder } }
  let(:obj)    { klass.new }
  let(:string) { "C\xC4\x83t\xC4\x83lin".force_encoding(Encoding::ASCII_8BIT) }

  describe 'deep_clean_strings' do
    it 'cleans strings on nested hashes' do
      expect(obj.deep_clean_strings(foo: { bar: string })[:foo][:bar]).to eq 'Cătălin'
    end

    it 'cleans strings on nested arrays' do
      expect(obj.deep_clean_strings([[string]])[0][0]).to eq 'Cătălin'
    end
  end
end
