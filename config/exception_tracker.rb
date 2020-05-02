require 'bugsnag'

Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
  config.project_root = '/app/src'
end

class SinatraApp < Sinatra::Base
  set :raise_errors, true
  use Bugsnag::Rack
end
