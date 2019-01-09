source 'https://rubygems.org'
ruby '2.5.3'

gem 'rake'
gem 'foreman'

gem 'shopify-sinatra-app', '~> 0.7.0'
gem 'sinatra-contrib'

gem 'kaminari-sinatra', git: 'https://github.com/kevinhughes27/kaminari-sinatra', ref: '2e7eb2771f921eaf75aab9dd21bf465876be3404'
gem 'kaminari-activerecord'

gem 'sidekiq'
gem 'redis'

gem 'wicked_pdf'
gem 'pony'
gem 'liquid'
gem 'raygun4ruby'

group :production do
  gem 'pg'
  gem 'wkhtmltopdf-heroku'
end

group :development do
  gem 'sqlite3'
  gem 'wkhtmltopdf-binary'
  gem 'pdf-inspector'
  gem 'letter_opener'
  gem 'rack-test'
  gem 'database_cleaner'
  gem 'fakeweb'
  gem 'mocha', require: false
  gem 'pry'
  gem 'byebug'
end
