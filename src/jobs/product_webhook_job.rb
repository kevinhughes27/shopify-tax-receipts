class ProductWebhookJob < Job
  def perform(shop_name, shopify_product)
    if product = Product.find_by(shop: shop_name, product_id: shopify_product['id'])
      product.update!({shopify_product: shopify_product.to_json})
    end
  end
end
