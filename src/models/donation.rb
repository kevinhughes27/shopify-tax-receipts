class Donation < ActiveRecord::Base
  validates_presence_of :shop, :order_id, :donation_amount
  validates_uniqueness_of :order_id, scope: :shop, conditions: -> { where("status != 'void' or status is null") }
  validates :status, inclusion: { in: %w(thresholded resent update void) }, allow_nil: true

  before_create :set_donation_number

  def email_template
    product_ids = order.line_items.map { |item| item.product_id }
    products = Product.where(shop: shop, product_id: product_ids)

    # default template for multiple products
    # or for no products (test email)
    if products.size == 1
      products.first.email_template
    else
      nil
    end
  end

  def resent!
    update!({status: 'resent'})
  end

  def void!
    update!({status: 'void'})
  end

  def void
    status == 'void'
  end

  def thresholded
    status == 'thresholded'
  end

  def order
    @order ||= load_order
  end

  def received_at
    Time.parse(order.created_at).strftime("%B %d, %Y")
  end

  delegate :email, to: :order
  delegate :billing_address, to: :order

  delegate :first_name,
           :last_name,
           :company,
           :address1,
           :address2,
           :city,
           :province,
           :country,
           :zip,
           to: :billing_address

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
      'province' => province,
      'country' => country,
      'zip' => zip,
      'received_at' => received_at,
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
    ShopifyAPI::Session.temp(domain: shop.name, token: shop.token, api_version: '2019-04') do
      yield
    end
  end

  def set_donation_number
    last_donation = Donation.where(shop: self.shop).order(id: :desc).limit(1).first
    last_number = last_donation.present? ? last_donation.donation_number : 0
    self.donation_number = last_number + 1
  end
end
