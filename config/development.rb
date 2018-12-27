require 'byebug'
require 'sinatra/reloader'

class SinatraApp < Sinatra::Base
  register Sinatra::Reloader

  # debug webhooks
  ## view
  get '/webhooks' do
    shopify_session do |shop_name|
      @webhooks = ShopifyAPI::Webhook.all
      erb :webhooks
    end
  end

  ## delete
  delete '/webhooks' do
    shopify_session do |shop_name|
      ShopifyAPI::Webhook.find(params["id"]).destroy
      flash[:notice] = "Webhook Removed"
      redirect '/webhooks'
    end
  end
end
