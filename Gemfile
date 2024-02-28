source 'https://rubygems.org'

ruby '3.2.2'

gem 'sidekiq-pro', source: 'https://gems.contribsys.com'

gem 'travis-exceptions',      git: 'https://github.com/travis-ci/travis-exceptions', branch: 'prd-ruby-upgrade-dev'
gem 'travis-logger',          git: 'https://github.com/travis-ci/travis-logger', branch: 'prd-ruby-upgrade-dev'
gem 'travis-metrics',         git: 'https://github.com/travis-ci/travis-metrics', branch: 'prd-ruby-upgrade-dev'

gem 'travis-config',          git: 'https://github.com/travis-ci/travis-config', branch: 'prd-ruby-upgrade-dev'
gem 'travis-encrypt',         git: 'https://github.com/travis-ci/travis-encrypt', branch: 'prd-ruby-upgrade-dev'
gem 'travis-lock',            git: 'https://github.com/travis-ci/travis-lock', branch: 'prd-ruby-upgrade-dev'
gem 'travis-rollout', '~> 0.0.2'
gem 'travis-support', git: 'https://github.com/travis-ci/travis-support', branch: 'prd-ruby-upgrade-dev'

gem 'metriks',                 git: 'https://github.com/travis-ci/metriks', branch: 'prd-ruby-upgrade-dev'
gem 'metriks-librato_metrics', git: 'https://github.com/travis-ci/metriks-librato_metrics', branch: 'prd-ruby-upgrade-dev'

gem 'marginalia', git: 'https://github.com/travis-ci/marginalia', branch: 'prd-ruby-upgrade-dev'

gem 'activerecord', '~> 7'
gem 'bunny'
gem 'dalli'
gem 'faraday'
gem 'pg', '~> 1'
gem 'rake'
gem 'redis', '~> 5'
gem 'rollout', git: 'https://github.com/travis-ci/rollout', branch: 'prd-ruby-upgrade-dev'

gem 'coder'
gem 'gh', git: 'https://github.com/travis-ci/gh', branch: 'prd-ruby-upgrade-dev'
gem 'keen'
gem 'multi_json'
gem 'redlock'
gem 'sentry-ruby'
gem 'simple_states', git: 'https://github.com/travis-ci/simple_states', branch: 'master'

gem 'jwt'
gem 'libhoney'
gem 'puma', '~> 6'
gem 'rack-ssl'
gem 'sinatra', '~> 3'

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
  gem 'rubocop-performance'
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
end
