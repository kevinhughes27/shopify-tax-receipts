require 'kaminari/sinatra'
require 'kaminari/activerecord'

Kaminari.configure do |config|
  config.params_on_first_page = true
end
