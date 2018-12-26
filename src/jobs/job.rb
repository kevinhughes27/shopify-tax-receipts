class Job
  include Sidekiq::Worker

  def activate_shopify_api(shop_name)
    shop = Shop.find_by(name: shop_name)
    api_session = ShopifyAPI::Session.new(shop.name, shop.token)
    ShopifyAPI::Base.activate_session(api_session)
  end
end
