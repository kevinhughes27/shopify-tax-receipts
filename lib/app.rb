require './lib/base'

class Charity < ActiveRecord::Base
  belongs_to :shop
  validates_presence_of :name, :charity_id
end

class Product < ActiveRecord::Base
  belongs_to :shop
  validates_presence_of :product_id
  validates_uniqueness_of :product_id, scope: :shop
end

class SinatraApp < ShopifyApp

  # Home page
  get '/' do
    shopify_session do |shop_name|
      @shop = Shop.find_by(name: shop_name)
      @charity = Charity.find_by(shop: @shop)
      @products = Product.where(shop: @shop)
      erb :home
    end
  end

  post '/order.json' do
    binding.pry
  end

  post '/charity' do
    shopify_session do |shop_name|
      shop = Shop.find_by(name: shop_name)
      params.merge!(shop: shop)

      charity = Charity.new(params)

      if charity.save
        flash[:notice] = "Charity Information Saved"
      else
        flash[:error] = "Error Saving Charity Information"
      end

      redirect '/'
    end
  end

  get '/products' do
    shopify_session do |shop_name|
      shop = Shop.find_by(name: shop_name)

      params["ids"].each do |id|
        product = Product.new(shop: shop, product_id: id)
        product.save
      end

      redirect '/'
    end
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
