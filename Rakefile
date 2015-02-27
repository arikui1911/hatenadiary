require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'
require 'yard/rake/yardoc_task'

Rake::TestTask.new(:test) do |t|
  t.loader = :testrb
end

YARD::Rake::YardocTask.new(:yard) do |t|
  t.options = ["--no-private"]
end

desc "Generate YARD document and fix some files"
task :doc => :yard do |t|
  mv "doc/_index.html", "doc/index.html"
end

task :default => :test




