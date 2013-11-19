#!/usr/bin/env rake
require 'rake'
require 'rspec/core/rake_task'

task :default => 'test:quick'

namespace :test do

  begin
    require 'rubocop/rake_task'

    desc 'Runs Rubocop against the cookbook.'
    task :rubocop do
      Rubocop::RakeTask.new
    end
  rescue LoadError
    warn "Rubocop not loaded, skipping style enforcement"
  end

  begin
    require 'foodcritic'

    task :default => [:foodcritic]
    FoodCritic::Rake::LintTask.new do |t|
      t.options = {:fail_tags => %w/correctness services libraries deprecated/ }
    end
  rescue LoadError
    warn "Foodcritic Is missing ZOMG"
  end

  # require 'strainer/rake_task'
 # Strainer::RakeTask.new(:strainer) do |s|
 #   s.strainerfile = 'Strainerfile'
 # end

  begin
    require 'kitchen/rake_tasks'
    Kitchen::RakeTasks.new
  rescue LoadError
    puts '>>>>> Kitchen gem not loaded, omitting tasks' unless ENV['CI']
  end

  begin
    require 'cane/rake_task'

    desc "Run cane to check quality metrics"
    Cane::RakeTask.new(:quality) do |cane|
      canefile = ".cane"
      cane.abc_max = 10
      cane.abc_glob =  '{recipes,libraries,resources,providers}/**/*.rb'
      cane.abc_exclude = %w(Helpers::Dns#build_resources Helpers::Dns#collect_txt)
      cane.no_style = true
      cane.parallel = true
    end

    task :default => :quality
  rescue LoadError
    warn "cane not available, quality task not provided."
  end

  desc 'Run all of the quick tests.'
  task :quick do
    Rake::Task['test:rubocop'].invoke
    Rake::Task['test:foodcritic'].invoke
    Rake::Task['test:quality'].invoke
  end

  desc 'Run _all_ the tests. Go get a coffee.'
  task :complete do
    Rake::Task['test:quick'].invoke
    Rake::Task['test:kitchen:all'].invoke
  end

  desc 'Run CI tests'
  task :ci do
    Rake::Task['test:complete'].invoke
  end
end


namespace :release do
  task :update_metadata do
  end

  task :tag_release do
  end
end
