require './lib/base'

class Charity < ActiveRecord::Base
  belongs_to :shop
  attr_accessor :name
end

class Product < ActiveRecord::Base
  belongs_to :shop
  attr_accessor :product_id
end

class SinatraApp < ShopifyApp

  # Home page
  get '/' do
    shopify_session do |shop_name|
      @shop = Shop.find_by(:name => shop_name)
      erb :home
    end
  end

  get '/order' do
    # new order from shopify
    # webhook_session do |shop, params|
    # end
  end

  post '/charity' do
    # save charity details
    flash[:notice] = "Saved"
    #flash[:error] = "Error"
    redirect '/'
  end

  post '/products' do
    byebug
  end

  private

  def install
    shopify_session do
      params = YAML.load(File.read("config/app.yml"))

      order_webhook = ShopifyAPI::Webhook.new(params["order_webhook"])
      uninstall_webhook = ShopifyAPI::Webhook.new(params["uninstall_webhook"])

      # create the order webhook if not present
      unless ShopifyAPI::Webhook.find(:all).include?(order_webhook)
        order_webhook.save
      end

      # create the uninstall webhook if not present
      unless ShopifyAPI::Webhook.find(:all).include?(uninstall_webhook)
        uninstall_webhook.save
      end
    end
    redirect '/'
  end

  def uninstall
    # webhook_session do |shop, params|
    #   # remove any dependent models
    #   # remove shop model
    #   shop.destroy
    # end
  end

end
