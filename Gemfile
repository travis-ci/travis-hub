source 'https://rubygems.org'

ruby '2.2.2' if ENV.key?('DYNO')

gem 'travis-exceptions',      github: 'travis-ci/travis-exceptions'
gem 'travis-logger',          github: 'travis-ci/travis-logger'
gem 'travis-metrics',         github: 'travis-ci/travis-metrics'
gem 'travis-instrumentation', github: 'travis-ci/travis-instrumentation'

gem 'travis-config', github: 'travis-ci/travis-config'
gem 'travis-encrypt'
gem 'travis-lock', github: 'travis-ci/travis-lock'

gem 'rake'
gem 'redis'
gem 'dalli'
gem 'activerecord'
gem 'sidekiq'

gem 'gh'
gem 'metriks-librato_metrics'
gem 'sentry-raven'
gem 'simple_states'
gem 'multi_json'
gem 'coder'
gem 'redlock'

platform :ruby do
  gem 'jemalloc'
  gem 'pg'
  gem 'bunny'
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
end
