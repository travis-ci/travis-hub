source 'https://rubygems.org'

ruby '1.9.3', engine: 'jruby', engine_version: '1.7.16' if ENV.key?('DYNO')

gem 'travis-support', github: 'travis-ci/travis-support', ref: 'sf-instrumentation'
# gem 'travis-support', path: '../travis-support'
gem 'travis-config',  '~> 0.1.0'
gem 'travis-encrypt', '~> 0.0.1'

gem 'rake'
gem 'redis'
gem 'dalli'
gem 'redlock'
gem 'activerecord'
gem 'sidekiq'
gem 'celluloid', '0.16.0' # 0.16.1 was yanked, and sidekiq 3.4.2 does not yet allow 0.17.x

gem 'gh'
gem 'metriks-librato_metrics'
gem 'sentry-raven',  github: 'getsentry/raven-ruby'
gem 'simple_states', '~> 1.1.0.rc5'
# gem 'simple_states', path: '../../simple_states'
gem 'coder'
gem 'multi_json'

platform :ruby do
  gem 'pg'
end

platform :jruby do
  gem 'march_hare'
  gem 'jruby-openssl', '~> 0.9.8', require: false
  gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3.0' # see http://www.ruby-forum.com/topic/4409725
  gem 'unlimited-jce-policy-jdk7', github: 'travis-ci/unlimited-jce-policy-jdk7'
end

group :test do
  gem 'rspec'
  gem 'mocha'
  gem 'database_cleaner'
  gem 'factory_girl'
end
