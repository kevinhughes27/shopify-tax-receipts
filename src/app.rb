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
require_relative 'routes/gdpr'

require_relative 'utils/donation_service'
require_relative 'utils/email_service'
require_relative 'utils/render_pdf'
require_relative 'utils/export_csv'

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
      @donations = Donation.where(shop: current_shop_name).order('created_at DESC').page(params[:donations_page])
      @tab = params[:tab] || 'products'
      erb :home
    end
  end

  # Help page
  get '/help' do
    erb :help
  end

  # order/paid webhook receiver
  post '/order.json' do
    webhook_session do |order|
      return unless order['customer']
      return unless order['customer']['email']

      donations = donations_from_order(current_shop_name, order)

      unless donations.empty?
        charity = Charity.find_by(shop: current_shop_name)
        shopify_shop = ShopifyAPI::Shop.current
        donation_amount = sprintf( "%0.02f", donations.sum)

        if donation = save_donation(current_shop_name, order, donation_amount)
          receipt_pdf = render_pdf(shopify_shop, charity, donation)
          deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf)
        end
      end
    end
  end

  # view a donation receipt pdf
  get '/view' do
    shopify_session do
      donation = Donation.find_by(shop: current_shop_name, id: params['id'])
      charity = Charity.find_by(shop: current_shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      receipt_pdf = render_pdf(shopify_shop, charity, donation)
      content_type 'application/pdf'
      receipt_pdf
    end
  end

  # resend a donation receipt
  post '/resend' do
    shopify_session do
      donation = Donation.find_by(shop: current_shop_name, id: params['id'])
      charity = Charity.find_by(shop: current_shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      if donation.void
        flash[:error] = "Donation is void"
      elsif donation.refunded
        flash[:error] = "Donation is refunded"
      else
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf)
        flash[:notice] = "Email resent!"
      end

      @tab = 'donations'
      redirect '/'
    end
  end

  # void a donation receipt
  post '/void' do
    shopify_session do
      donation = Donation.find_by(shop: current_shop_name, id: params['id'])
      charity = Charity.find_by(shop: current_shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      if donation.void
        flash[:error] = "Donation is void"
      elsif donation.refunded
        flash[:error] = "Donation is refunded"
      else
        donation.void!
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_void_receipt(shopify_shop, charity, donation, receipt_pdf)
        flash[:notice] = "Donation voided"
      end

      @tab = 'donations'
      redirect '/'
    end
  end

  # render a preview of user edited email template
  get '/preview_email' do
    shopify_session do
      charity = Charity.find_by(shop: current_shop_name)
      template = params['template']
      body = email_body(template, charity, mock_donation)

      {email_body: body}.to_json
    end
  end

  # send a test email to the user
  get '/test_email' do
    shopify_session do
      donation = mock_donation
      charity = Charity.find_by(shop: current_shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      charity.assign_attributes(charity_params(params))

      if params['email_template'].present?
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf, params['email_to'])
      elsif params['void_email_template'].present?
        donation.assign_attributes({status: 'void'})
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_void_receipt(shopify_shop, charity, donation, receipt_pdf, params['email_to'])
      end

      status 200
    end
  end

  # render a preview of the user edited pdf template
  get '/preview_pdf' do
    shopify_session do
      donation = mock_donation
      charity = Charity.find_by(shop: current_shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      receipt_pdf = render_pdf(shopify_shop, charity, donation)
      content_type 'application/pdf'
      receipt_pdf
    end
  end

  # export donations
  post '/export' do
    shopify_session do
      start_date = Date.parse(params['start_date'])
      end_date = Date.parse(params['end_date'])

      csv = export_csv(current_shop_name, start_date, end_date)
      attachment   'donations.csv'
      content_type 'application/csv'
      csv
    end
  end

  private

  def mock_donation
    mock_order = JSON.parse( File.read(File.join('test', 'fixtures/order_webhook.json')) )
    build_donation(current_shop_name, mock_order, 20.00)
  end
end
