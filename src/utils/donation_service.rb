def build_donation(shop_name, order, donation_amount)
  donation = Donation.new(shop: shop_name, order_id: order['id'], donation_amount: donation_amount)
  donation.order = ShopifyAPI::Order.new(order)
  donation
end

def save_donation(shop_name, order, donation_amount)
  donation = build_donation(shop_name, order, donation_amount)
  donation.save!
  donation
rescue ActiveRecord::RecordInvalid => e
  raise unless e.message == 'Validation failed: Order has already been taken'
  false
end
