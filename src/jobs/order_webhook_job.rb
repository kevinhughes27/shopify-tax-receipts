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

    donation = Donation.create!(
      shop: shop_name,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: sprintf( "%0.02f", donation_amount)
    )

    receipt_pdf = render_pdf(shopify_shop, charity, donation)
    deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf)
  end

  private

  def donations_from_order(shop_name, order)
    donation_products = Product.where(shop: shop_name)

    donations = []

    order["line_items"].each do |item|
      donation_product = donation_products.detect { |product| product.product_id == item["product_id"] }
      if donation_product
        donations << item["price"].to_f * item["quantity"].to_i * (donation_product.percentage / 100.0)
      end
    end

    donations
  end
end
