class OrderWebhookJob < Job
  def perform(shop_name, order)
    return unless order['customer']
    return unless order['customer']['email']

    donations = donations_from_order(shop_name, order)
    donation_amount = donations.sum
    return if donations.empty?

    charity = Charity.find_by(shop: shop_name)
    return if charity.nil?

    activate_shopify_api(shop_name)
    shopify_shop = ShopifyAPI::Shop.current

    return if charity.receipt_threshold.present? && donation_amount < charity.receipt_threshold

    donation = build_donation(shop_name, order, donation_amount)
    donation.save!

    receipt_pdf = render_pdf(shopify_shop, charity, donation)
    deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf)
  end
end
