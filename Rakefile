require "bundler/gem_tasks"

task :default => %w{ spec }

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end
