class SinatraApp < Sinatra::Base
  # product index app link receiver
  get '/products' do
    shopify_session do |shop_name|
      add_products(shop_name, Array.wrap(params["ids"]))
      flash[:notice] = "Product(s) added!"
      redirect '/?tab=products'
    end
  end

  # product detail app link receiver
  get '/product' do
    shopify_session do |shop_name|
      add_products(shop_name, Array.wrap(params["id"]))
      flash[:notice] = "Product added!"
      redirect '/?tab=products'
    end
  end

  # update product
  put '/products' do
    shopify_session do |shop_name|
      product = Product.find_by(shop: shop_name, id: params["id"])
      product_params = params.slice('percentage')

      if product.update_attributes(product_params)
        flash[:notice] = "Product Updated"
      else
        flash[:error] = "Error!"
      end

      redirect '/?tab=products'
    end
  end

  # products/update webhook receiver
  post '/product_update' do
    shopify_webhook do |shop_name, product|
      ProductWebhookJob.perform_async(shop_name, product)
    end
  end

  # delete product (stops getting a donation receipt)
  delete '/products' do
    shopify_session do |shop_name|
      Product.find_by(shop: shop_name, id: params["id"]).destroy
      flash[:notice] = "Product Removed"
      redirect '/?tab=products'
    end
  end

  private

  def add_products(shop_name, product_ids)
    product_ids.each { |product_id| add_product(shop_name, product_id) }
  end

  def add_product(shop_name, product_id)
    shopify_product = ShopifyAPI::Product.find(product_id)

    Product.create!(
      shop: shop_name,
      product_id: product_id,
      shopify_product: shopify_product.to_json
    )

  rescue ActiveRecord::RecordInvalid => e
    raise unless e.message.include? "Product has already been taken"
  end
end
