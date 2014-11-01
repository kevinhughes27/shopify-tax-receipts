require 'sinatra/shopify-sinatra-app'
require './lib/charity_routes'
require './lib/pdf_generator'
require './lib/models/charity'
require './lib/models/product'
require 'pony'
require 'liquid'
require 'byebug'

class SinatraApp < Sinatra::Base
  register Sinatra::Shopify
  set :scope, 'read_products, read_orders'

  Pony.options = {
    :via => :smtp,
    :via_options => {
      :address => 'smtp.sendgrid.net',
      :port => '587',
      :domain => 'heroku.com',
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :authentication => :plain,
      :enable_starttls_auto => true
    }
  }

  # Home page
  get '/' do
    shopify_session do
      @charity = Charity.find_by(shop: current_shop_name)
      @products = Product.where(shop: current_shop_name)
      erb :home
    end
  end

  # Help page
  get '/help' do
    erb :help
  end

  # order/create webhook receiver
  post '/order.json' do
    webhook_session do |order|
      donation_product_ids = Product.where(shop: current_shop_name).pluck(:product_id)
      donations = []
      order["line_items"].each do |item|
        if donation_product_ids.include? item["product_id"]
          donations << item["price"].to_f * item["quantity"].to_i
        end
      end

      unless donations.empty?
        charity = Charity.find_by(shop: current_shop_name)
        shopify_shop = ShopifyAPI::Shop.current
        donation_amount = donations.sum
        receipt_pdf = generate_pdf(shopify_shop, order, charity, donation_amount)
        deliver_donation_receipt(shopify_shop, order, charity, receipt_pdf)
      end
    end
  end

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

  delete '/products' do
    Product.find_by(id: params["id"]).destroy
    flash[:notice] = "Product Removed"
    redirect '/'
  end

  private

  def install
    shopify_session do
      order_webhook = ShopifyAPI::Webhook.new({
        topic: "orders/create",
        address: "#{base_url}/order.json",
        format: "json"
      })
      order_webhook.save

      uninstall_webhook = ShopifyAPI::Webhook.new({
        topic: "app/uninstalled",
        address: "#{base_url}/uninstall",
        format: "json"
      })
      uninstall_webhook.save
    end
    redirect '/'
  end

  def add_products(product_ids)
    product_ids.each do |id|
      product = Product.new(shop: current_shop_name, product_id: id)
      product.save
    end
  end

  def generate_pdf(shop, order, charity, donation_amount)
    pdf_generator = PdfGenerator.new(shop: shop,
                                         charity: charity,
                                         order: order,
                                         donation_amount: donation_amount)
    pdf_generator.generate
  end

  def deliver_donation_receipt(shop, order, charity, pdf)
    email_body = liquid(:receipt_email, layout: false, locals: {order: order, charity: charity})
    Pony.mail to: order["customer"]["email"],
              from: "no-reply@#{shop.domain}",
              subject: "Donation receipt for #{charity.name}",
              attachments: {"tax_receipt.pdf" => pdf},
              body: email_body
  end

  def uninstall
    webhook_session do |params|
      Charity.where(shop: current_shop_name).destroy_all
      Product.where(shop: current_shop_name).destroy_all
      current_shop.destroy
    end
  end

end
