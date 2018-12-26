require 'raygun4ruby'
require 'raygun/sidekiq'

Raygun.setup do |config|
  config.api_key = ENV['RAYGUN_APIKEY']
end

class SinatraApp < Sinatra::Base
  set :raise_errors, true
  use Raygun::Middleware::RackExceptionInterceptor
end
