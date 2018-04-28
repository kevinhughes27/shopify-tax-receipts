require 'sinatra/shopify-sinatra-app'

require_relative '../config/pony'
require_relative '../config/pdf_engine'
require_relative '../config/exception_tracker'
require_relative '../config/pagination'
require_relative '../config/development' if ENV['DEVELOPMENT']

require_relative 'concerns/install'
require_relative 'models/charity'
require_relative 'models/product'
require_relative 'models/donation'
require_relative 'routes/charity'
require_relative 'routes/products'
require_relative 'routes/webhooks'
require_relative 'utils/render_pdf'

class SinatraApp < Sinatra::Base
  register Sinatra::Shopify
  set :scope, 'read_products, read_orders'

  register Kaminari::Helpers::SinatraHelpers

  # Home page
  get '/' do
    shopify_session do
      @shop = ShopifyAPI::Shop.current
      @charity = Charity.find_by(shop: current_shop_name)
      @products = Product.where(shop: current_shop_name).page(params[:products_page])
      @donations = Donation.where(shop: current_shop_name).page(params[:donations_page])
      @tab = params[:tab] || 'products'
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

        if donation = save_donation(current_shop_name, order, donation_amount)
          receipt_pdf = render_pdf(shopify_shop, order, charity, donation_amount)
          deliver_donation_receipt(shopify_shop, order, charity, receipt_pdf)
        end
      end
    end
  end

  # resend a donation receipt
  post '/resend' do
    shopify_session do
      donation = Donation.find_by(id: params['id'])

      charity = Charity.find_by(shop: current_shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      order = JSON.parse(donation.order.to_json)
      donation_amount = donation.donation_amount

      receipt_pdf = render_pdf(shopify_shop, order, charity, donation_amount)
      deliver_donation_receipt(shopify_shop, order, charity, receipt_pdf)

      flash[:notice] = "Email resent!"
      redirect '/'
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

  # render a preview of the user edited pdf template
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
      deliver_donation_receipt(shopify_shop, order, charity, receipt_pdf, params['to'])

      status 200
    end
  end

  private

  def save_donation(shop_name, order, donation_amount)
    donation = Donation.new(shop: shop_name, order_id: order['id'], donation_amount: donation_amount)
    donation.save!
    donation
  rescue ActiveRecord::RecordInvalid => e
    raise unless e.message == 'Validation failed: Order has already been taken'
    false
  end

  def deliver_donation_receipt(shop, order, charity, pdf, to = nil)
    return unless order["customer"]
    return unless to ||= order["customer"]["email"]

    bcc = charity.email_bcc
    from = charity.email_from || shop.email
    subject = charity.email_subject
    body = liquid(charity.email_template, layout: false, locals: {order: order, charity: charity})
    filename = charity.pdf_filename

    send_email(to, bcc, from, subject, body, pdf, filename)
  end

  def send_email(to, bcc, from, subject, body, pdf, filename)
    Pony.mail to: to,
              bcc: bcc,
              from: from,
              subject: subject,
              attachments: {"#{filename}.pdf" => pdf},
              body: body
  end

  def mock_order
    JSON.parse( File.read(File.join('test', 'fixtures/order_webhook.json')) )
  end
end
