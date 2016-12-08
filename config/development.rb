require 'byebug'
require 'sinatra/reloader'

class SinatraApp < Sinatra::Base
  register Sinatra::Reloader
end
