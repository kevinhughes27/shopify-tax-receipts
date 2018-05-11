class Donation < ActiveRecord::Base
  validates_presence_of :shop, :order_id, :donation_amount
  validates_uniqueness_of :order_id, scope: :shop

  delegate :address1,
           :city,
           :country,
           :zip,
           to: :address

  def order=(shopify_order)
    @order = shopify_order
  end

  def order
    @order ||= ShopifyAPI::Order.find(order_id)
  end

  def address
    order.billing_address || order.attributes.dig('default_address')
  end

  def email
    order.customer.email
  end

  def first_name
    address.first_name
  end

  def last_name
    address.last_name
  end

  def order_to_liquid
    drop = JSON.parse(order.to_json)
    drop['created_at'] = Time.parse(drop['created_at']).strftime("%B %d, %Y")
    drop['billing_address'] ||= drop.dig('default_address')
    drop
  end

  def to_liquid
    {
      'order_number' => order_number,
      'email' => email,
      'first_name' => first_name,
      'last_name' => last_name,
      'address1' => address1,
      'city' => city,
      'country' => country,
      'zip' => zip,
      'created_at' => (created_at || Time.now).strftime("%B %d, %Y"),
      'donation_amount' => sprintf( "%0.02f", donation_amount)
    }
  end
end
