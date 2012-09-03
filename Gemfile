source :rubygems

gem 'travis-core',        :git => 'git://github.com/travis-ci/travis-core'
gem 'travis-support',     :git => 'git://github.com/travis-ci/travis-support', :branch => 'sf-reduce-amqp-channels'

gem 'gh',                 :git => 'git://github.com/rkh/gh'
gem 'hubble',             :git => 'git://github.com/roidrage/hubble'
gem 'newrelic_rpm',       '~> 3.3.2'

# can't be removed yet, even though we're on jruby 1.6.7 everywhere
# this is due to Invalid gemspec errors
gem 'rollout',            :git => 'git://github.com/jamesgolick/rollout', :ref => 'v1.1.0'

gem 'hot_bunnies',        '~> 1.3.4'
gem 'jruby-openssl',      '~> 0.7.4'

gem 'activerecord-jdbcpostgresql-adapter', '~> 1.2.2'

group :test do
  gem 'rspec',            '~> 2.7.0'
  gem 'database_cleaner', '~> 0.7.1'
  gem 'mocha',            '~> 0.10.0'
  gem 'webmock',          '~> 1.8.0'
  gem 'guard'
  gem 'guard-rspec'
end

group :development, :test do
  gem 'micro_migrations', :git => 'git://gist.github.com/2087829.git'
  gem 'data_migrations',  '~> 0.0.1'
end
