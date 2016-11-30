require 'sinatra/shopify-sinatra-app'

class SinatraApp < Sinatra::Base
  get '/webhooks' do
    shopify_session do
      @webhooks = ShopifyAPI::Webhook.all
      erb :webhooks
    end
  end

  # delete '/webhooks' do
  #   shopify_session do
  #     ShopifyAPI::Webhook.find(params["id"]).destroy
  #     flash[:notice] = "Webhook Removed"
  #     redirect '/webhooks'
  #   end
  # end
end
