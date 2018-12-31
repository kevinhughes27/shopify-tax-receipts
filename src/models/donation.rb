class Donation < ActiveRecord::Base
  validates_presence_of :shop, :order_id, :donation_amount
  validates_uniqueness_of :order_id, scope: :shop, conditions: -> { where("status != 'void' or status is null") }
  validates :status, inclusion: { in: %w(resent update void) }, allow_nil: true

  def resent!
    update!({status: 'resent'})
  end

  def void!
    update!({status: 'void'})
  end

  def void
    status == 'void'
  end

  def order
    @order ||= load_order
  end

  def address
    order.billing_address || order.attributes.dig('default_address')
  end

  delegate :address1,
           :city,
           :country,
           :zip,
           to: :address

  def email
    order.customer.email
  end

  def first_name
    address.first_name
  end

  def last_name
    address.last_name
  end

  def original_donation=(donation)
    @original_donation = donation
  end

  def original_donation
    return nil unless status == 'update'
    return @original_donation if defined?(@original_donation)

    @original_donation = Donation
      .where(shop: shop, order_id: order_id, status: 'void')
      .order(id: :desc)
      .first
  end

  def order_to_liquid
    drop = JSON.parse(order.to_json)
    drop['created_at'] = Time.parse(drop['created_at']).strftime("%B %d, %Y")
    drop['billing_address'] ||= drop.dig('default_address')
    drop
  end

  def to_liquid
    {
      'id' => id,
      'order_number' => order_number,
      'status' => status,
      'email' => email,
      'first_name' => first_name,
      'last_name' => last_name,
      'address1' => address1,
      'city' => city,
      'country' => country,
      'zip' => zip,
      'created_at' => (created_at || Time.now).strftime("%B %d, %Y"),
      'donation_amount' => sprintf( "%0.02f", donation_amount),
      'original_donation' => original_donation && original_donation.to_liquid
    }
  end

  private

  def load_order
    if read_attribute(:order).present?
      shopify_order = JSON.parse(read_attribute(:order))
      ShopifyAPI::Order.new(shopify_order)
    else
      with_shopify_api do
        shopify_order = ShopifyAPI::Order.find(order_id)
        update_column(:order, shopify_order.to_json)
        shopify_order
      end
    end
  end

  def with_shopify_api
    shop = Shop.find_by(name: self.shop)
    ShopifyAPI::Session.temp(shop.name, shop.token) do
      yield
    end
  end
end
