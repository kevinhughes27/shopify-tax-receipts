class OrderWebhookJob
  include Sidekiq::Worker

  def perform(shop_name, order)
    shop = Shop.find_by(name: shop_name)
    api_session = ShopifyAPI::Session.new(shop.name, shop.token)
    ShopifyAPI::Base.activate_session(api_session)

    donations = donations_from_order(shop_name, order)

    unless donations.empty?
      charity = Charity.find_by(shop: shop_name)
      shopify_shop = ShopifyAPI::Shop.current
      donation_amount = sprintf( "%0.02f", donations.sum)

      if donation = save_donation(shop_name, order, donation_amount)
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf)
      end
    end
  end
end
