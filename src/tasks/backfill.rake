task :backfill_products do
  #Shop.find_each { |shop| backfill_products(shop) }
  shop = Shop.find_by(name: 'hawker-supplies.myshopify.com')
  backfill_products(shop)

  shop = Shop.find_by(name: 'samadeyemi.myshopify.com')
  backfill_products(shop)
end

def backfill_products(shop)
  puts "Backfilling shop: #{shop.name}"

  products = Product.where(shop: shop.name, shopify_product: nil)

  return unless products.present?

  api_session = ShopifyAPI::Session.new(shop.name, shop.token)
  ShopifyAPI::Base.activate_session(api_session)

  products.each do |product|
    shopify_product = ShopifyAPI::Product.find(product.product_id)
    product.shopify_product = shopify_product.to_json
    product.save!
    sleep(0.1)
  end

rescue => e
  puts "Error backfilling for shop #{shop.name} error: #{e}"
end
