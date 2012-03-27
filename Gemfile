source :rubygems

# see https://gist.github.com/2063855
base ||= 'git://github.com/travis-ci'
type = base[0, 2] == '..' ? :path : :git

gem 'travis-core',     type => "#{base}/travis-core", :require => 'travis/engine', :ref => 'rollout'
gem 'travis-support',  type => "#{base}/travis-support"

gem 'hot_bunnies',          '~> 1.3.4'
gem 'jruby-openssl',        '~> 0.7.4'

gem 'activerecord-jdbcpostgresql-adapter', '1.2.2'
gem 'activerecord-jdbc-adapter',           '1.2.2'

gem 'gh'
gem 'metriks',              :git => 'git://github.com/mattmatt/metriks.git', :ref => 'source'
gem 'hubble',               :git => 'git://github.com/mattmatt/hubble.git'
gem 'newrelic_rpm',         '~> 3.3.2'
gem 'redis',                '~> 2.2.0'
gem 'rollout',              :git => 'git://github.com/jamesgolick/rollout', :ref => 'v1.1.0'

group :test do
  gem 'rspec',              '~> 2.7.0'
  gem 'database_cleaner',   '~> 0.7.1'
  gem 'mocha',              '~> 0.10.0'
  gem 'webmock',            '~> 1.8.0'
end
