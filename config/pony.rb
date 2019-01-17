require 'pony'
require 'letter_opener' if ENV['DEVELOPMENT']

class SinatraApp < Sinatra::Base
  if ENV['RACK_ENV'] == 'test'
    Pony.options = {
      :via => :test
    }
  elsif ENV['DEVELOPMENT']
    Pony.options = {
      :via => LetterOpener::DeliveryMethod,
      :via_options => {:location => File.expand_path('../../tmp/letter_opener', __FILE__)}
    }
  else
    Pony.options = {
      :via => :smtp,
      :via_options => {
        :address => 'smtp.sendgrid.net',
        :port => '587',
        :domain => 'heroku.com',
        :user_name => ENV['SENDGRID_USERNAME'],
        :password => ENV['SENDGRID_PASSWORD'],
        :authentication => :plain,
        :enable_starttls_auto => true
      }
    }
  end
end
