source 'https://rubygems.org'

ruby '1.9.3', engine: 'jruby', engine_version: '1.7.19' if ENV.key?('DYNO')

gem 'travis-core',        github: 'travis-ci/travis-core'
gem 'travis-support',     github: 'travis-ci/travis-support'
gem 'travis-config',      '~> 0.1.0'
gem 'travis-sidekiqs',    github: 'travis-ci/travis-sidekiqs', require: nil

gem 'unlimited-jce-policy-jdk7', github: 'travis-ci/unlimited-jce-policy-jdk7'

gem 'dalli'

gem 'sentry-raven',       github: 'getsentry/raven-ruby'
gem 'metriks-librato_metrics'
gem 'rails_12factor'

# can't be removed yet, even though we're on jruby 1.6.7 everywhere
# this is due to Invalid gemspec errors
gem 'rollout',            github: 'jamesgolick/rollout', ref: 'v1.1.0'
gem 'sidekiq'

gem 'march_hare',         '~> 2.7.0'
gem 'jruby-openssl',      '~> 0.9.4', require: false

# see http://www.ruby-forum.com/topic/4409725
gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3.0'

gem 'coder',              github: 'rkh/coder'

group :test do
  gem 'database_cleaner', '~> 0.8.0'
  gem 'guard'
  gem 'guard-rspec'
  gem 'mocha',            '~> 0.10.0'
  gem 'rspec',            '~> 2.7.0'
  gem 'rubocop',          require: false
  gem 'ruby-progressbar', '1.7.1' # this should not be needed, but rubygems is giving me an old version for some reason, well, a newer version which was yanked
  gem 'simplecov',        require: false
  gem 'webmock',          '~> 1.8.0'
end

group :development, :test do
  gem 'micro_migrations'
end
