require 'sinatra/shopify-sinatra-app'
require 'sinatra/content_for'
require 'sinatra/partial'

require './lib/charity_controller'
require './lib/models/charity'
require './lib/models/product'
require './lib/pdf_generator'

require 'tilt/liquid'
require 'raygun4ruby'
require 'pony'

class SinatraApp < Sinatra::Base
  register Sinatra::Shopify
  set :scope, 'read_products, read_orders'

  register Sinatra::Partial
  set :partial_template_engine, :erb
  enable :partial_underscores

  helpers Sinatra::ContentFor

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

  unless ENV['DEVELOPMENT']
    Raygun.setup do |config|
      config.api_key = ENV['RAYGUN_APIKEY']
    end

    use Raygun::Middleware::RackExceptionInterceptor
  end

  # Home page
  get '/' do
    shopify_session do
      @shop = ShopifyAPI::Shop.current
      @charity = Charity.find_by(shop: current_shop_name)
      @products = Product.where(shop: current_shop_name)
      erb :home
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

  # delete product (stops getting a donation receipt)
  delete '/products' do
    Product.find_by(id: params["id"]).destroy
    flash[:notice] = "Product Removed"
    redirect '/'
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

  # render a preview of user edited email template
  get '/preview_email' do
    shopify_session do
      charity = Charity.find_by(shop: current_shop_name)
      subject = params['subject']
      template = params['template']
      email_body = liquid(template, layout: false, locals: {order: mock_order, charity: charity})

      {email_subject: subject, email_body: email_body, email_template: template}.to_json
    end
  end

  # send a test email to the user
  get '/test_email' do
    shopify_session do
      charity = Charity.find_by(shop: current_shop_name)
      shopify_shop = ShopifyAPI::Shop.current
      order = mock_order

      receipt_pdf = generate_pdf(shopify_shop, order, charity, 20)
      deliver_test_receipt(shopify_shop, order, charity, receipt_pdf, params)

      status 200
    end
  end

  # receive uninstall webhook
  post '/uninstall' do
    webhook_session do |params|
      Charity.where(shop: current_shop_name).destroy_all
      Product.where(shop: current_shop_name).destroy_all
      current_shop.destroy
    end
  end

  private

  def after_shopify_auth
    shopify_session do
      create_order_webhook
      create_uninstall_webhook
    end
  end

  def create_order_webhook
    return if ENV['DEVELOPMENT']

    order_webhook = ShopifyAPI::Webhook.new({
      topic: "orders/create",
      address: "#{base_url}/order.json",
      format: "json"
    })
    order_webhook.save!
  rescue => e
    raise unless order_webhook.persisted?
  end

  def create_uninstall_webhook
    return if ENV['DEVELOPMENT']

    uninstall_webhook = ShopifyAPI::Webhook.new({
      topic: "app/uninstalled",
      address: "#{base_url}/uninstall",
      format: "json"
    })
    uninstall_webhook.save!
  rescue => e
    raise unless uninstall_webhook.persisted?
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
    return unless order["customer"]
    return unless mail_to = order["customer"]["email"]
    return unless order["billing_address"]
    email_body = liquid(charity.email_template, layout: false, locals: {order: order, charity: charity})

    Pony.mail to: mail_to,
              from: shop.email,
              subject: charity.email_subject,
              attachments: {"tax_receipt.pdf" => pdf},
              body: email_body
  end

  def deliver_test_receipt(shop, order, charity, pdf, params = {})
    email_to = params["to"] || shop.email
    email_subject = params["subject"] || charity.email_subject
    email_body = liquid(params["template"] || charity.email_template, layout: false, locals: {order: order, charity: charity})

    Pony.mail to: email_to,
              from: shop.email,
              subject: email_subject,
              attachments: {"tax_receipt.pdf" => pdf},
              body: email_body
  end

  def mock_order
    JSON.parse( File.read(File.join('test', 'fixtures/order_webhook.json')) )
  end
end
