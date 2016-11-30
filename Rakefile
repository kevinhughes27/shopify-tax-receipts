require 'sinatra/activerecord/rake'
require 'resque/tasks'
require 'rake/testtask'
require './lib/app'

task :clear do
  Rake::Task["clear_products"].invoke
  Rake::Task["clear_charities"].invoke
  Rake::Task["clear_shops"].invoke
end

task :clear_shops do
  Shop.delete_all
end

task :clear_charities do
  Charity.delete_all
end

task :clear_products do
  Product.delete_all
end

namespace :test do
  task :prepare do
    `RACK_ENV=test rake db:create`
    `RACK_ENV=test rake db:migrate`
  end
end

task :test do
  Rake::TestTask.new do |t|
    t.pattern = 'test/*_test.rb'
    t.libs << 'test'
    t.verbose = true
  end
end
