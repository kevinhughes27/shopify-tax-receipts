source 'https://rubygems.org'
ruby '2.6.6'

gem 'rake'
gem 'puma'

gem 'sinatra', '~> 3.0.4'
gem 'shopify-sinatra-app'
gem 'sinatra-flash'
gem 'sinatra-contrib', '~> 3.0.4'
gem 'activerecord', '5.2.3'

gem 'kaminari-sinatra', git: 'https://github.com/kevinhughes27/kaminari-sinatra', ref: '2e7eb2771f921eaf75aab9dd21bf465876be3404'
gem 'kaminari-activerecord'

gem 'sidekiq'
gem 'redis'

gem 'wicked_pdf', '~> 2.6.3'
gem 'pony'
gem 'liquid'
gem 'bugsnag', '~> 6.24'

group :production do
  gem 'pg'
  gem 'wkhtmltopdf-heroku', '2.12.6.0'
end

group :development do
  gem 'sqlite3'
  gem 'wkhtmltopdf-binary', '0.12.6.5'
  gem 'pdf-inspector'
  gem 'letter_opener'
  gem 'rack-test'
  gem 'database_cleaner'
  gem 'fakeweb'
  gem 'mocha', require: false
  gem 'pry'
  gem 'byebug'
end
