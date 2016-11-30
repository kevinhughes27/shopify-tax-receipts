require 'sinatra/shopify-sinatra-app'
require './lib/models/product'

class SinatraApp < Sinatra::Base
  # product index app link receiver
  get '/products' do
    shopify_session do
      add_products(Array.wrap(params["ids"]))
      flash[:notice] = "Product(s) added!"
      redirect '/'
    end
  end

  # product index app link receiver
  get '/product' do
    shopify_session do
      add_products(Array.wrap(params["id"]))
      flash[:notice] = "Product added!"
      redirect '/'
    end
  end

  # update product
  put '/products' do
    product = Product.find_by(id: params["id"])
    product_params = params.slice('percentage')

    if product.update_attributes(product_params)
      flash[:notice] = "Product Updated"
    else
      flash[:error] = "Error!"
    end

    redirect '/'
  end

  # delete product (stops getting a donation receipt)
  delete '/products' do
    Product.find_by(id: params["id"]).destroy
    flash[:notice] = "Product Removed"
    redirect '/'
  end

  private

  def add_products(product_ids)
    product_ids.each do |id|
      begin
        Product.create!(shop: current_shop_name, product_id: id)
      rescue ActiveRecord::RecordInvalid => e
        raise unless e.message.include? "Product has already been taken"
      end
    end
  end
end
