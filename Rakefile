require 'rake'

namespace :db do
  desc 'Create the test database'
  task :create do
    sh 'createdb travis' rescue nil
    sh 'psql -q < spec/support/db.sql'
  end
end
