require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'
require 'yard/rake/yardoc_task'

Rake::TestTask.new(:test) do |t|
  t.loader = :testrb
end

YARD::Rake::YardocTask.new do |t|
  t.options ||= []
  t.options << "--no-private"
end

task :default => :test




