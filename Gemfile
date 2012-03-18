source :rubygems

# see https://gist.github.com/2063855
base ||= 'git://github.com/travis-ci'
type = base[0, 2] == '..' ? :path : :git

gem 'travis-core',     type => "#{base}/travis-core", :ref => 'magnum', :require => 'travis/engine'
gem 'travis-support',  type => "#{base}/travis-support"

gem 'hot_bunnies',          '~> 1.3.4'
gem 'jruby-openssl',        '~> 0.7.4'

gem 'activerecord-jdbcpostgresql-adapter', '1.2.2'
gem 'activerecord-jdbc-adapter',           '1.2.2'

gem 'airbrake'
gem 'metriks',              :git => 'git://github.com/mattmatt/metriks.git', :ref => 'source'


gem 'newrelic_rpm',         '~> 3.3.2'

group :test do
  gem 'rspec',              '~> 2.7.0'
  gem 'database_cleaner',   '~> 0.7.1'
  gem 'mocha',              '~> 0.10.0'
  gem 'webmock',            '~> 1.8.0'
end
