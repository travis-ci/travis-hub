require 'bundler/setup'
require 'rake'
require 'travis'

begin
  require 'micro_migrations'
  require 'rspec/core/rake_task'
  require 'rubocop/rake_task'
rescue LoadError => e
  warn e
end

ENV['DB_STRUCTURE'] = "#{Gem.loaded_specs['travis-core'].full_gem_path}/db/structure.sql"

RuboCop::RakeTask.new if defined?(RuboCop)

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = './spec/**/*_spec.rb'
end if defined?(RSpec)

task default: :spec
