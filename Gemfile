source 'https://rubygems.org'

ruby '3.2.2'

gem 'sidekiq', '~> 7.2.0'
gem 'sidekiq-pro', source: 'https://gems.contribsys.com'

gem 'travis-exceptions',      git: 'https://github.com/travis-ci/travis-exceptions'
gem 'travis-logger',          git: 'https://github.com/travis-ci/travis-logger'
gem 'travis-metrics',         git: 'https://github.com/travis-ci/travis-metrics'

gem 'metriks', git: 'https://github.com/travis-ci/metriks'
gem 'metriks-librato_metrics', git: 'https://github.com/travis-ci/metriks-librato_metrics'
gem 'travis-config', git: 'https://github.com/travis-ci/travis-config'
gem 'travis-encrypt', git: 'https://github.com/travis-ci/travis-encrypt'
gem 'travis-lock', git: 'https://github.com/travis-ci/travis-lock'
gem 'travis-rollout', git: 'https://github.com/travis-ci/travis-rollout'
gem 'travis-support', git: 'https://github.com/travis-ci/travis-support'

gem 'marginalia', git: 'https://github.com/travis-ci/marginalia'

gem 'activerecord', '~> 7'
gem 'addressable', '~> 2.8.6'
gem 'bunny'
gem 'dalli'
gem 'faraday'
gem 'pg', '~> 1'
gem 'rake'
gem 'redis'
gem 'rollout', git: 'https://github.com/travis-ci/rollout'

gem 'coder'
gem 'gh', git: 'https://github.com/travis-ci/gh', branch: 'master'
gem 'keen'
gem 'multi_json'
gem 'redlock'
gem 'sentry-ruby'
gem 'simple_states', git: 'https://github.com/travis-ci/simple_states', branch: 'master'

gem 'jwt'
gem 'libhoney'
gem 'puma', '~> 6.4', '>= 6.4.3'
gem 'rack', '~> 2.2', '>= 2.2.20'
gem 'rack-ssl'
gem 'rexml', '>= 3.3.9'
gem 'sinatra', '~> 3.2'

group :test do
  gem 'database_cleaner'
  gem 'factory_bot'
  gem 'mocha', '~> 2'
  gem 'pry'
  gem 'rack-test'
  gem 'rspec', '~> 3.12'
  gem 'sinatra-contrib'
  gem 'webmock'
end

group :development, :test do
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
end
