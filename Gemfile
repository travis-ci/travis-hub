source 'https://rubygems.org'

ruby '1.9.3', engine: 'jruby', engine_version: '1.7.16' if ENV.key?('DYNO')

gem 'unlimited-jce-policy-jdk7', github: 'travis-ci/unlimited-jce-policy-jdk7'

gem 'travis-support',     github: 'travis-ci/travis-support'
gem 'travis-config',      '~> 0.1.0'
gem 'travis-sidekiqs',    github: 'travis-ci/travis-sidekiqs', require: nil

gem 'redis'
gem 'dalli'
gem 'sentry-raven',       github: 'getsentry/raven-ruby'
gem 'metriks-librato_metrics'
gem 'rails_12factor'
gem 'simple_states'
gem 'activerecord',       '~> 3'

# can't be removed yet, even though we're on jruby 1.6.7 everywhere
# this is due to Invalid gemspec errors
gem 'rollout',            github: 'jamesgolick/rollout', ref: 'v1.1.0'
gem 'sidekiq'
gem 'coercible'
gem 'virtus'
gem 'gh'

# gem 'march_hare',         '~> 2.0.0.rc2'
# gem 'jruby-openssl',      '~> 0.8.8', require: false
# gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3.0' # see http://www.ruby-forum.com/topic/4409725
gem 'pg'

gem 'coder',              github: 'rkh/coder'
gem 'multi_json'

group :test do
  gem 'database_cleaner', '~> 0.8.0'
  gem 'mocha',            '~> 0.10.0'
  gem 'rspec',            '~> 2.7.0'
  gem 'factory_girl'
end

group :development, :test do
  gem 'micro_migrations'
end
