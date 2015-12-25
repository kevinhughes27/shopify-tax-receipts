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
    `RACK_ENV=test SECRET=secret rake db:seed`
  end
end

task :test do
  Rake::TestTask.new do |t|
    t.pattern = 'test/*_test.rb'
    t.libs << 'test'
    t.verbose = true
  end
end

namespace :resque do
  task :info do
    puts Resque.info
  end

  task :queues do
    puts Resque.queues
  end

  task :redis do
    puts Resque.redis
  end

  task :size do
    puts Resque.size(:default)
  end

  task :peek do
    puts Resque.peek(:default)
  end

  task :working do
    puts Resque.working
  end

  task :failed do
    puts Resque::Failure.count
  end

  task :failed_backtrace do
    Resque::Failure.all(0,5).reverse.each { |job|
       backtrace = job["backtrace"].join("\n")
       puts "#{job["exception"]} \n #{backtrace} \n\n"
    }
  end

  task :retry_failed do
    (Resque::Failure.count-1).downto(0).each { |i| Resque::Failure.requeue(i) }
  end

  task :clear_failures do
    Resque::Failure.clear
  end
end
