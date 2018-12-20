require 'sinatra/activerecord/rake'
require 'rake/testtask'
require './src/app'

namespace :test do
  task :prepare do
    `RACK_ENV=test rake db:setup`
    `RACK_ENV=test rake db:migrate`
  end
end

task :test do
  Rake::TestTask.new do |t|
    t.pattern = 'test/*_test.rb'
    t.libs << 'test'
  end
end
