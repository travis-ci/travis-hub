source 'https://rubygems.org'

ruby '2.4.1' if ENV['DYNO']

gem 'sidekiq-pro', source: 'https://gems.contribsys.com'

gem 'travis-exceptions',      git: 'https://github.com/travis-ci/travis-exceptions'
gem 'travis-logger',          git: 'https://github.com/travis-ci/travis-logger'
gem 'travis-metrics',         git: 'https://github.com/travis-ci/travis-metrics'
gem 'travis-instrumentation', git: 'https://github.com/travis-ci/travis-instrumentation'

gem 'travis-config',          git: 'https://github.com/travis-ci/travis-config'
gem 'travis-encrypt',         git: 'https://github.com/travis-ci/travis-encrypt', ref: 'sf-ruby-2.4.1'
gem 'travis-lock',            git: 'https://github.com/travis-ci/travis-lock'
gem 'travis-support',         git: 'https://github.com/travis-ci/travis-support'
gem 'travis-rollout',         git: 'https://github.com/travis-ci/travis-rollout', branch: 'sf-refactor'

gem 'rake'
gem 'jemalloc'
gem 'pg'
gem 'bunny'
gem 'redis'
gem 'redis-namespace'
gem 'dalli'
gem 'activerecord'
gem 'faraday'

gem 'gh'
gem 'keen'
gem 'metriks-librato_metrics'
gem 'sentry-raven'
gem 'simple_states', git: 'https://github.com/svenfuchs/simple_states', ref: 'sf-ruby-2.4.1'
gem 'multi_json'
gem 'coder'
gem 'redlock'

gem 'puma'
gem 'rack-ssl'
gem 'sinatra'
gem 'jwt'

group :test do
  gem 'rspec'
  gem 'mocha'
  gem 'bourne'
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'webmock'
  gem 'sinatra-contrib'
end
