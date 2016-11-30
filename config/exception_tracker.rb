require 'raygun4ruby'

class SinatraApp < Sinatra::Base
  unless ENV['DEVELOPMENT']
    Raygun.setup do |config|
      config.api_key = ENV['RAYGUN_APIKEY']
    end

    set :raise_errors, true
    use Raygun::Middleware::RackExceptionInterceptor
  end
end
