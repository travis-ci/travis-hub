source :rubygems

ruby '1.9.3', engine: 'jruby', engine_version: '1.7.0'

gem 'travis-core',        github: 'travis-ci/travis-core'
gem 'travis-support',     github: 'travis-ci/travis-support'
gem 'travis-sidekiqs',    github: 'travis-ci/travis-sidekiqs', require: nil

# TODO need to release the gem as soon i'm certain this change makes sense
gem 'simple_states',      github: 'svenfuchs/simple_states', branch: 'sf-set-state-early'

gem 'gh',                 github: 'rkh/gh'
gem 'hubble',             github: 'roidrage/hubble'
gem 'newrelic_rpm',       '~> 3.4.2'

# can't be removed yet, even though we're on jruby 1.6.7 everywhere
# this is due to Invalid gemspec errors
gem 'rollout',            github: 'jamesgolick/rollout', ref: 'v1.1.0'
gem 'sidekiq'

gem 'hot_bunnies',        '~> 1.4.0.pre4'
gem 'jruby-openssl',      '~> 0.7.7'

gem 'activerecord-jdbcpostgresql-adapter', '~> 1.2.2'

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
