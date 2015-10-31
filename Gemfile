source 'https://rubygems.org'

ruby '2.2.2', engine: 'jruby', engine_version: '9.0.3.0' if ENV.key?('DYNO')

gem 'travis-amqp',            github: 'travis-ci/travis-amqp'
gem 'travis-exceptions',      github: 'travis-ci/travis-exceptions'
gem 'travis-logger',          github: 'travis-ci/travis-logger'
gem 'travis-metrics',         github: 'travis-ci/travis-metrics'
gem 'travis-instrumentation', github: 'travis-ci/travis-instrumentation'

gem 'travis-config',   '~> 1.0.0rc1'
gem 'travis-encrypt'
gem 'travis-lock'

gem 'rake'
gem 'redis'
gem 'dalli'
gem 'activerecord'
gem 'sidekiq'

gem 'gh'
gem 'metriks-librato_metrics'
gem 'sentry-raven'
# gem 'simple_states', '~> 2.0.0.rc1'
# gem 'simple_states', path: '../../simple_states'
gem 'simple_states', github: 'svenfuchs/simple_states', ref: '2.x'
gem 'multi_json'

platform :ruby do
  gem 'pg'
  gem 'jemalloc'
end

platform :jruby do
  gem 'march_hare'
  gem 'jruby-openssl', require: false
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'unlimited-jce-policy-jdk7', github: 'travis-ci/unlimited-jce-policy-jdk7'
end

group :test do
  gem 'rspec'
  gem 'mocha'
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'bunny', platform: :ruby
end
