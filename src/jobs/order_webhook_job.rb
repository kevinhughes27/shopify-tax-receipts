class OrderWebhookJob < Job
  def perform(shop_name, order)
    activate_shopify_api(shop_name)

    donations = donations_from_order(shop_name, order)
    return if donations.empty?

    charity = Charity.find_by(shop: shop_name)
    shopify_shop = ShopifyAPI::Shop.current
    donation_amount = donations.sum

    return if charity.receipt_threshold.present? &&
      donation_amount < charity.receipt_threshold

    if donation = save_donation(shop_name, order, donation_amount)
      receipt_pdf = render_pdf(shopify_shop, charity, donation)
      deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf)
    end
  end
end
