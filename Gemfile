source 'https://rubygems.org'

gem 'sidekiq-pro', source: 'https://gems.contribsys.com'

gem 'travis-exceptions',      github: 'travis-ci/travis-exceptions'
gem 'travis-logger',          github: 'travis-ci/travis-logger'
gem 'travis-metrics',         github: 'travis-ci/travis-metrics'
gem 'travis-instrumentation', github: 'travis-ci/travis-instrumentation'
# TODO: back out travis-config on 'meat-logs-readonly-config' branch
gem 'travis-config',          github: 'travis-ci/travis-config', branch: 'meat-logs-readonly-config'
gem 'travis-encrypt'
gem 'travis-lock',            github: 'travis-ci/travis-lock'
gem 'travis-migrations',      github: 'travis-ci/travis-migrations'
# TODO: back out travis-support on 'meat-logs-readonly-config' branch
gem 'travis-support',         github: 'travis-ci/travis-support', branch: 'meat-logs-readonly-config'

gem 'rake'
gem 'redis'
gem 'redis-namespace'
gem 'dalli'
gem 'activerecord'
gem 'faraday'

gem 'gh'
gem 'metriks-librato_metrics'
gem 'sentry-raven'
gem 'simple_states'
gem 'multi_json'
gem 'coder'
gem 'redlock'
gem 'pry'

platform :ruby do
  gem 'jemalloc'
  gem 'pg'
  gem 'bunny'
end

group :test do
  gem 'rspec'
  gem 'mocha'
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'webmock'
end
