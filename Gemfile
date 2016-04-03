source 'https://rubygems.org'
ruby '2.2.3'

gem 'rake'
gem 'foreman'

gem 'shopify-sinatra-app', '~> 0.3.0'
gem 'sinatra-contrib'
gem 'sinatra-partial'

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
  gem 'letter_opener'
  gem 'rack-test'
  gem 'fakeweb'
  gem 'mocha', require: false
  gem 'pry'
  gem 'byebug'
end
