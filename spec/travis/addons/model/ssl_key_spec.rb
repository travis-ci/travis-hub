describe SslKey do
  let(:key) { described_class.new }

  before do
    generate_keys(key)
  end

  def generate_keys(key)
    pair = OpenSSL::PKey::RSA.generate(1024)
    key.public_key  = pair.public_key.to_s
    key.private_key = pair.to_pem
  end

  describe 'generate_keys' do
    it 'generates the public key' do
      expect(key.public_key).to be_a(String)
    end

    it 'generates the private key' do
      expect(key.private_key).to be_a(String)
    end
  end

  describe 'encrypt' do
    it 'encrypts something' do
      expect(key.encrypt('hello')).to_not be_nil
      expect(key.encrypt('hello')).to_not eql 'hello'
    end

    it 'is decryptable' do
      encrypted = key.encrypt('hello')
      expect(key.decrypt(encrypted)).to eql 'hello'
    end
  end

  describe 'decrypt' do
    it 'decrypts something' do
      encrypted_string = key.encrypt('hello world')
      expect(key.decrypt(encrypted_string)).to_not be_nil
      expect(key.decrypt(encrypted_string)).to_not eql 'hello'
    end
  end
end
