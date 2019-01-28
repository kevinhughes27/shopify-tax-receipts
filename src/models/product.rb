class Product < ActiveRecord::Base
  validates_presence_of :shop, :product_id
  validates_uniqueness_of :product_id, scope: :shop

  def title
    shopify_product['title'] || product_id
  end

  def description
    shopify_product['body_html'] || ''
  end

  private

  def shopify_product
    @shopify_product ||= JSON.parse(read_attribute(:shopify_product) || "{}")
  end
end
