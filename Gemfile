source 'https://rubygems.org'

ruby '1.9.3', engine: 'jruby', engine_version: '1.7.4'

gem 'travis-core',        github: 'travis-ci/travis-core'
gem 'travis-support',     github: 'travis-ci/travis-support'
gem 'travis-sidekiqs',    github: 'travis-ci/travis-sidekiqs', require: nil

gem 'dalli'

gem 'sentry-raven',       github: 'getsentry/raven-ruby'
gem 'newrelic_rpm',       '~> 3.4.2'

# can't be removed yet, even though we're on jruby 1.6.7 everywhere
# this is due to Invalid gemspec errors
gem 'rollout',            github: 'jamesgolick/rollout', ref: 'v1.1.0'
gem 'sidekiq'

gem 'march_hare',         '~> 2.0.0.rc2'
gem 'jruby-openssl',      '~> 0.8.8'

# see http://www.ruby-forum.com/topic/4409725
gem 'activerecord-jdbcpostgresql-adapter', '~> 1.2.9'

gem 'coder',              github: 'rkh/coder'

group :test do
  gem 'rspec',            '~> 2.7.0'
  gem 'database_cleaner', '~> 0.8.0'
  gem 'mocha',            '~> 0.10.0'
  gem 'webmock',          '~> 1.8.0'
  gem 'guard'
  gem 'guard-rspec'
end

group :development, :test do
  gem 'micro_migrations', git: 'https://gist.github.com/2087829.git'
  gem 'data_migrations',  '~> 0.0.1'
end
