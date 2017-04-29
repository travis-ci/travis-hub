describe Travis::Hub::Config do
  let(:config) { described_class.load }

  describe 'resource urls' do
    describe 'with a TRAVIS_DATABASE_URL set' do
      before { ENV['TRAVIS_DATABASE_URL'] = 'postgres://username:password@host:1234/database' }
      after  { ENV.delete('TRAVIS_DATABASE_URL') }

      it { expect(config.database.username).to eq 'username' }
      it { expect(config.database.password).to eq 'password' }
      it { expect(config.database.host).to eq 'host' }
      it { expect(config.database.port).to eq 1234 }
      it { expect(config.database.database).to eq 'database' }
      it { expect(config.database.encoding).to eq 'unicode' }
      it { expect(config.database.variables.application_name).to_not be_empty }
      it { expect(config.database.variables.statement_timeout).to eq 10000 }
    end

    describe 'with a DATABASE_URL set' do
      before { ENV['DATABASE_URL'] = 'postgres://username:password@host:1234/database' }
      after  { ENV.delete('DATABASE_URL') }

      it { expect(config.database.username).to eq 'username' }
      it { expect(config.database.password).to eq 'password' }
      it { expect(config.database.host).to eq 'host' }
      it { expect(config.database.port).to eq 1234 }
      it { expect(config.database.database).to eq 'database' }
      it { expect(config.database.encoding).to eq 'unicode' }
      it { expect(config.database.variables.application_name).to_not be_empty }
      it { expect(config.database.variables.statement_timeout).to eq 10000 }
    end

    describe 'with a TRAVIS_LOGS_DATABASE_URL set' do
      before { ENV['TRAVIS_LOGS_DATABASE_URL'] = 'postgres://username:password@host:1234/database' }
      after  { ENV.delete('TRAVIS_LOGS_DATABASE_URL') }

      it { expect(config.logs_database.username).to eq 'username' }
      it { expect(config.logs_database.password).to eq 'password' }
      it { expect(config.logs_database.host).to eq 'host' }
      it { expect(config.logs_database.port).to eq 1234 }
      it { expect(config.logs_database.database).to eq 'database' }
      it { expect(config.logs_database.encoding).to eq 'unicode' }
      it { expect(config.logs_database.variables.application_name).to_not be_empty }
      it { expect(config.logs_database.variables.statement_timeout).to eq 10000 }
    end

    describe 'with a LOGS_DATABASE_URL set' do
      before { ENV['LOGS_DATABASE_URL'] = 'postgres://username:password@host:1234/database' }
      after  { ENV.delete('LOGS_DATABASE_URL') }

      it { expect(config.logs_database.username).to eq 'username' }
      it { expect(config.logs_database.password).to eq 'password' }
      it { expect(config.logs_database.host).to eq 'host' }
      it { expect(config.logs_database.port).to eq 1234 }
      it { expect(config.logs_database.database).to eq 'database' }
      it { expect(config.logs_database.encoding).to eq 'unicode' }
      it { expect(config.logs_database.variables.application_name).to_not be_empty }
      it { expect(config.logs_database.variables.statement_timeout).to eq 10000 }
    end

    describe 'with a TRAVIS_RABBITMQ_URL set' do
      before { ENV['TRAVIS_RABBITMQ_URL'] = 'amqp://username:password@host:1234/vhost' }
      after  { ENV.delete('TRAVIS_RABBITMQ_URL') }

      it { expect(config.amqp.username).to eq 'username' }
      it { expect(config.amqp.password).to eq 'password' }
      it { expect(config.amqp.host).to eq 'host' }
      it { expect(config.amqp.port).to eq 1234 }
      it { expect(config.amqp.vhost).to eq 'vhost' }
    end

    describe 'with a RABBITMQ_URL set' do
      before { ENV['RABBITMQ_URL'] = 'amqp://username:password@host:1234/vhost' }
      after  { ENV.delete('RABBITMQ_URL') }

      it { expect(config.amqp.username).to eq 'username' }
      it { expect(config.amqp.password).to eq 'password' }
      it { expect(config.amqp.host).to eq 'host' }
      it { expect(config.amqp.port).to eq 1234 }
      it { expect(config.amqp.vhost).to eq 'vhost' }
    end

    describe 'with a TRAVIS_REDIS_URL set' do
      before { ENV['TRAVIS_REDIS_URL'] = 'redis://username:password@host:1234' }
      after  { ENV.delete('TRAVIS_REDIS_URL') }

      it { expect(config.redis.url).to eq 'redis://username:password@host:1234' }
    end

    describe 'with a REDIS_URL set' do
      before { ENV['REDIS_URL'] = 'redis://username:password@host:1234' }
      after  { ENV.delete('REDIS_URL') }

      it { expect(config.redis.url).to eq 'redis://username:password@host:1234' }
    end
  end
end
