require 'rake'

desc 'Create the test database'
task :db_setup do
  sh 'psql -q < spec/support/db.sql'
end
