source 'https://rubygems.org'
ruby '2.5.3'

gem 'rake'
gem 'foreman'

gem 'shopify-sinatra-app', git: 'https://github.com/kevinhughes27/shopify-sinatra-app', ref: '8b8ae4dfa0760ecb67a5d42746840aaf79ecf53e'
gem 'sinatra-contrib'

gem 'kaminari-sinatra', git: 'https://github.com/kevinhughes27/kaminari-sinatra', ref: '2e7eb2771f921eaf75aab9dd21bf465876be3404'
gem 'kaminari-activerecord'

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
