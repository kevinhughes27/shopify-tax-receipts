require 'sinatra/activerecord/rake'
require 'rake/testtask'
require './src/app'

Rake.add_rakelib 'src/tasks'

namespace :test do
  task :prepare do
    `DISABLE_DATABASE_ENVIRONMENT_CHECK=1 RACK_ENV=test rake db:setup`
    `DISABLE_DATABASE_ENVIRONMENT_CHECK=1 RACK_ENV=test rake db:migrate`
  end
end

task :test do
  Rake::TestTask.new do |t|
    t.pattern = 'test/*_test.rb'
    t.libs << 'test'
  end
end
