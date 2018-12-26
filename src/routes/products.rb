require 'sinatra/shopify-sinatra-app'
require_relative '../models/product'

class SinatraApp < Sinatra::Base
  # product index app link receiver
  get '/products' do
    shopify_session do |shop_name|
      add_products(shop_name, Array.wrap(params["ids"]))
      flash[:notice] = "Product(s) added!"
      redirect '/'
    end
  end

  # product index app link receiver
  get '/product' do
    shopify_session do |shop_name|
      add_products(shop_name, Array.wrap(params["id"]))
      flash[:notice] = "Product added!"
      redirect '/'
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

      redirect '/'
    end
  end

  # delete product (stops getting a donation receipt)
  delete '/products' do
    shopify_session do |shop_name|
      Product.find_by(shop: shop_name, id: params["id"]).destroy
      flash[:notice] = "Product Removed"
      redirect '/'
    end
  end

  private

  def add_products(shop_name, product_ids)
    product_ids.each do |id|
      begin
        Product.create!(shop: shop_name, product_id: id)
      rescue ActiveRecord::RecordInvalid => e
        raise unless e.message.include? "Product has already been taken"
      end
    end
  end
end
