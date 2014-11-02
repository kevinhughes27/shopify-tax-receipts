require 'sinatra/activerecord/rake'
require 'resque/tasks'
require 'rake/testtask'
require './lib/app'

task :deploy do
  pipe = IO.popen("git push heroku master --force")
  while (line = pipe.gets)
    print line
  end
end

task :clear_my_shop do
  shop_name = "kevins-sweet-test-shop.myshopify.com"
  Charity.where(shop: shop_name).destroy_all
  Product.where(shop: shop_name).destroy_all
  Shop.where(name: shop_name).destroy_all
end

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

task :creds2heroku do
  Bundler.with_clean_env {
    api_key = `sed -n '1p' .env`
    shared_secret = `sed -n '2p' .env`
    secret = `sed -n '3p' .env`

    `heroku config:set #{api_key}`
    `heroku config:set #{shared_secret}`
    `heroku config:set #{secret}`
  }
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
