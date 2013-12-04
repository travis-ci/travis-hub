require 'rake'
require 'rspec/core/rake_task'
require 'bundler/setup'
require 'micro_migrations'
require 'travis'

ENV['DB_STRUCTURE'] = "#{Gem.loaded_specs['travis-core'].full_gem_path}/db/structure.sql"

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = './spec/**/*_spec.rb'
end

task :default => :spec



