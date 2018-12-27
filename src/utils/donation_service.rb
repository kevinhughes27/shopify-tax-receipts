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

def build_donation(shop_name, order, donation_amount)
  donation = Donation.new(
    shop: shop_name,
    order_id: order['id'],
    order_number: order['name'],
    donation_amount: sprintf( "%0.02f", donation_amount)
  )

  donation.order = ShopifyAPI::Order.new(order)

  donation
end
