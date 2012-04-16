source :rubygems

gem 'travis-core',        :git => "git://github.com/travis-ci/travis-core", :require => 'travis/engine', :branch => 'pull-requests'
gem 'travis-support',     :git => "git://github.com/travis-ci/travis-support"

gem 'gh',                 :git => 'git://github.com/rkh/gh'
gem 'metriks',            :git => 'git://github.com/mattmatt/metriks', :ref => 'source'
gem 'hubble',             :git => 'git://github.com/mattmatt/hubble'
gem 'newrelic_rpm',       '~> 3.3.2'

# can be removed as soon as we're on jruby 1.6.7 everywhere
gem 'rollout',            :git => 'git://github.com/jamesgolick/rollout', :ref => 'v1.1.0'

platform :jruby do
  gem 'hot_bunnies',      '~> 1.3.4'
  gem 'jruby-openssl',    '~> 0.7.4'

  gem 'activerecord-jdbcpostgresql-adapter', '1.2.2'
  gem 'activerecord-jdbc-adapter',           '1.2.2'
end

group :test do
  gem 'rspec',            '~> 2.7.0'
  gem 'database_cleaner', '~> 0.7.1'
  gem 'mocha',            '~> 0.10.0'
  gem 'webmock',          '~> 1.8.0'
end
