require 'sinatra/shopify-sinatra-app'
require 'sinatra/content_for'
require 'sinatra/partial'
require 'sinatra/reloader'

require './lib/charity_controller'
require './lib/products_controller'

require './lib/models/charity'
require './lib/models/product'

require 'tilt/liquid'
require 'wicked_pdf'
require 'raygun4ruby'
require 'pony'

if ENV['DEVELOPMENT']
  require 'letter_opener'
  require 'byebug'
else
  require 'wkhtmltopdf-heroku'
end

class SinatraApp < Sinatra::Base
  register Sinatra::Shopify
  set :scope, 'read_products, read_orders'

  register Sinatra::Partial
  set :partial_template_engine, :erb
  enable :partial_underscores

  helpers Sinatra::ContentFor

  if ENV['DEVELOPMENT']
    register Sinatra::Reloader

    Pony.options = {
      :via => LetterOpener::DeliveryMethod,
      :via_options => {:location => File.expand_path('/tmp/letter_opener', __FILE__)}
    }
  else
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

    Raygun.setup do |config|
      config.api_key = ENV['RAYGUN_APIKEY']
    end

    set :raise_errors, true
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

  # Help page
  get '/help' do
    erb :help
  end

  get '/webhooks' do
    shopify_session do
      @webhooks = ShopifyAPI::Webhook.all
      erb :webhooks
    end
  end

  # delete '/webhooks' do
  #   shopify_session do
  #     ShopifyAPI::Webhook.find(params["id"]).destroy
  #     flash[:notice] = "Webhook Removed"
  #     redirect '/webhooks'
  #   end
  # end

  # order/create webhook receiver
  post '/order.json' do
    webhook_session do |order|
      donation_products = Product.where(shop: current_shop_name)

      donations = []
      order["line_items"].each do |item|
        donation_product = donation_products.detect { |product| product.product_id == item["product_id"] }
        if donation_product
          donations << item["price"].to_f * item["quantity"].to_i * (donation_product.percentage / 100.0)
        end
      end

      unless donations.empty?
        charity = Charity.find_by(shop: current_shop_name)
        shopify_shop = ShopifyAPI::Shop.current
        donation_amount = sprintf( "%0.02f", donations.sum)
        receipt_pdf = render_pdf(shopify_shop, order, charity, donation_amount)
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

  get '/preview_pdf' do
    shopify_session do
      charity = Charity.find_by(shop: current_shop_name)
      shopify_shop = ShopifyAPI::Shop.current
      donation_amount = '20.00'
      order = mock_order

      receipt_pdf = render_pdf(shopify_shop, order, charity, donation_amount)
      content_type 'application/pdf'
      receipt_pdf
    end
  end

  # send a test email to the user
  get '/test_email' do
    shopify_session do
      charity = Charity.find_by(shop: current_shop_name)
      shopify_shop = ShopifyAPI::Shop.current
      order = mock_order

      receipt_pdf = render_pdf(shopify_shop, order, charity, 20)
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
    raise unless webhook_already_created?(order_webhook)
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
    raise unless webhook_already_created?(uninstall_webhook)
  end

  def webhook_already_created?(webhook)
    webhook.errors.messages[:address].present? &&
    webhook.errors.messages[:address].include?("for this topic has already been taken")
  end

  def render_pdf(shop, order, charity, donation_amount)
    order['created_at'] = Time.parse(order['created_at']).strftime("%B %d, %Y")

    template = Tilt::LiquidTemplate.new { |t| charity.pdf_template }
    pdf_content = template.render(
      shop: shop.attributes,
      order: order,
      charity: charity,
      donation_amount: donation_amount
    )

    WickedPdf.new.pdf_from_string(
      Tilt::ERBTemplate.new('views/receipt_pdf.erb').render(Object.new, pdf_content: pdf_content)
    )
  end

  def deliver_donation_receipt(shop, order, charity, pdf)
    return unless order["customer"]
    return unless mail_to = order["customer"]["email"]
    return unless order["billing_address"]
    email_body = liquid(charity.email_template, layout: false, locals: {order: order, charity: charity})

    Pony.mail to: mail_to,
              from: shop.email,
              subject: charity.email_subject,
              attachments: {"donation_receipt.pdf" => pdf},
              body: email_body
  end

  def deliver_test_receipt(shop, order, charity, pdf, params = {})
    email_to = params["to"] || shop.email
    email_subject = params["subject"] || charity.email_subject
    email_body = liquid(params["template"] || charity.email_template, layout: false, locals: {order: order, charity: charity})

    Pony.mail to: email_to,
              from: shop.email,
              subject: email_subject,
              attachments: {"donation_receipt.pdf" => pdf},
              body: email_body
  end

  def mock_order
    JSON.parse( File.read(File.join('test', 'fixtures/order_webhook.json')) )
  end
end
