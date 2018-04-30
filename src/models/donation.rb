class Donation < ActiveRecord::Base
  validates_presence_of :shop, :order_id, :donation_amount
  validates_uniqueness_of :order_id, scope: :shop

  delegate :order_number,
           :first_name,
           :last_name,
           :address1,
           :city,
           :country,
           :zip,
           to: :order

  def order
    @order ||= ShopifyAPI::Order.find(order_id)
  end

  def donation_amount
    sprintf( "%0.02f", read_attribute(:donation_amount))
  end
end
