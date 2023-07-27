source 'https://rubygems.org'

ruby '3.2.2'

gem 'sidekiq-pro', source: 'https://gems.contribsys.com'

gem 'travis-exceptions',      git: 'https://github.com/travis-ci/travis-exceptions', branch: 'prd-ruby-upgrade-dev'
gem 'travis-logger',          git: 'https://github.com/travis-ci/travis-logger', branch: 'prd-ruby-upgrade-dev'
gem 'travis-metrics',      path: '~/tmp/travis-metrics' #   git: 'https://github.com/travis-ci/travis-metrics', branch: 'prd-ruby-upgrade-dev'

gem 'travis-config',          git: 'https://github.com/travis-ci/travis-config', branch: 'prd-ruby-upgrade-dev'
gem 'travis-encrypt',         git: 'https://github.com/travis-ci/travis-encrypt', branch: 'prd-ruby-upgrade-dev'
gem 'travis-lock',            git: 'https://github.com/travis-ci/travis-lock', branch: 'prd-ruby-upgrade-dev'
gem 'travis-support',         git: 'https://github.com/travis-ci/travis-support', branch: 'prd-ruby-upgrade-dev'
gem 'travis-rollout', '~> 0.0.2'

gem 'metriks',                 git: 'https://github.com/travis-ci/metriks', branch: 'prd-ruby-upgrade-dev'
gem 'metriks-librato_metrics', git: 'https://github.com/travis-ci/metriks-librato_metrics', branch: 'prd-ruby-upgrade-dev'

gem 'marginalia', git: 'https://github.com/travis-ci/marginalia', branch: 'prd-ruby-upgrade-dev'

gem 'rake'
gem 'jemalloc'
gem 'pg', '~> 1'
gem 'bunny'
gem 'redis', '~> 5'
gem 'rollout', git: 'https://github.com/travis-ci/rollout', branch: 'prd-ruby-upgrade-dev'
gem 'dalli'
gem 'activerecord', '~> 7'
gem 'faraday'

gem 'gh', git: 'https://github.com/travis-ci/gh', branch: 'prd-ruby-upgrade-dev'
gem 'keen'
gem 'sentry-ruby'
gem 'simple_states', path: '~/tmp/simple_states' #git: 'https://github.com/travis-ci/simple_states', branch: 'prd-ruby-upgrade-dev'
gem 'multi_json'
gem 'coder'
gem 'redlock'

gem 'puma', '~> 6'
gem 'rack-ssl'
gem 'sinatra', '~> 3'
gem 'jwt'
gem 'libhoney'

group :test do
  gem 'rspec', '~> 3.12'
  gem 'mocha', '~> 2'
  gem 'database_cleaner'
  gem 'factory_bot'
  gem 'webmock'
  gem 'sinatra-contrib'
  gem 'rack-test'
  gem 'pry'
end

group :development, :test do
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
end
