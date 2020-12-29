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
        :user_name => 'apikey',
        :password => ENV['SENDGRID_API_KEY'],
        :authentication => :plain,
        :enable_starttls_auto => true
      }
    }
    # Pony.options = {
    #   :via => :smtp,
    #   :via_options => {
    #     :port           => ENV['MAILGUN_SMTP_PORT'],
    #     :address        => ENV['MAILGUN_SMTP_SERVER'],
    #     :user_name      => ENV['MAILGUN_SMTP_LOGIN'],
    #     :password       => ENV['MAILGUN_SMTP_PASSWORD'],
    #     :domain         => 'taxreceipts.heroku.com',
    #     :authentication => :plain,
    #   }
    # }
  end
end
