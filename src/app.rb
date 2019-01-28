require 'sinatra/shopify-sinatra-app'

require_relative '../config/pony'
require_relative '../config/sidekiq'
require_relative '../config/exception_tracker' unless ENV['DEVELOPMENT']
require_relative '../config/pdf_engine'
require_relative '../config/pagination'
require_relative '../config/development' if ENV['DEVELOPMENT']

require_relative 'models/charity'
require_relative 'models/product'
require_relative 'models/donation'

require_relative 'jobs/job'
require_relative 'jobs/after_install_job'
require_relative 'jobs/order_webhook_job'
require_relative 'jobs/product_webhook_job'
require_relative 'jobs/export_csv_job'
require_relative 'jobs/uninstall_job'

require_relative 'utils/email_service'
require_relative 'utils/render_pdf'

require_relative 'routes/charity'
require_relative 'routes/products'
require_relative 'routes/gdpr'

class SinatraApp < Sinatra::Base
  register Sinatra::Shopify
  set :scope, 'read_products, read_orders, read_all_orders'

  register Kaminari::Helpers::SinatraHelpers

  def after_shopify_auth
    shopify_session do |shop_name|
      AfterInstallJob.perform_async(shop_name)
    end
  end

  # Home page
  get '/' do
    shopify_session do |shop_name|
      @shop = ShopifyAPI::Shop.current
      @charity = Charity.find_by(shop: shop_name)
      @products = Product.where(shop: shop_name)
      @donations = Donation.where(shop: shop_name)

      # default tab
      @tab = params[:tab]
      @tab ||= if @donations.present?
        'donations'
      else
        'products'
      end

      # order app actions (filter by order)
      @order_ids = []
      @order_ids << params[:id] if params[:id]
      @order_ids.concat(params[:ids]) if params[:ids]

      if @order_ids.present?
        @donations = @donations.where(order_id: @order_ids)
        @tab = 'donations'
      end

      # search
      if params[:donation_search].present?
        @donation_search = params[:donation_search]
        @donations = @donations.where('"order" LIKE :query', query: "%#{@donation_search}%")
        @tab = 'donations'
      end

      if params[:product_search].present?
        @product_search = params[:product_search]
        @products = @products.where('shopify_product LIKE :query', query: "%#{@product_search}%")
        @tab = 'products'
      end

      # pagination
      @donations = @donations.order('created_at DESC').page(params[:donations_page])
      @products = @products.page(params[:products_page])

      erb :home
    end
  end

  # Help page
  get '/help' do
    shopify_session do |shop_name|
      @shop = ShopifyAPI::Shop.current
      erb :help
    end
  end

  # receive uninstall webhook
  post '/uninstall' do
    shopify_webhook do |shop_name, params|
      UninstallJob.perform_async(shop_name)
    end
  end

  # orders/updated webhook receiver
  post '/order' do
    shopify_webhook do |shop_name, order|
      OrderWebhookJob.perform_async(shop_name, order)
    end
  end

  # view a donation receipt pdf
  get '/view' do
    shopify_session do |shop_name|
      donation = Donation.find_by(shop: shop_name, id: params['id'])
      charity = Charity.find_by(shop: shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      receipt_pdf = render_pdf(shopify_shop, charity, donation)
      content_type 'application/pdf'
      receipt_pdf
    end
  end

  # resend a donation receipt
  post '/resend' do
    shopify_session do |shop_name|
      donation = Donation.find_by(shop: shop_name, id: params['id'])
      charity = Charity.find_by(shop: shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      if donation.void
        flash[:error] = "Donation is void"
      elsif donation.thresholded
        donation.update!({status: nil})
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf)
        flash[:notice] = "Email sent!"
      else
        donation.resent!
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf)
        flash[:notice] = "Email resent!"
      end

      redirect '/?tab=donations'
    end
  end

  # void a donation receipt
  post '/void' do
    shopify_session do |shop_name|
      donation = Donation.find_by(shop: shop_name, id: params['id'])
      charity = Charity.find_by(shop: shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      if donation.void
        flash[:error] = "Donation is void"
      elsif donation.thresholded
        donation.void!
        flash[:notice] = "Donation voided"
      else
        donation.void!
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_void_receipt(shopify_shop, charity, donation, receipt_pdf)
        flash[:notice] = "Donation voided"
      end

      redirect '/?tab=donations'
    end
  end

  # render a preview of user edited email template
  get '/preview_email' do
    shopify_session do |shop_name|
      donation = mock_donation(shop_name)
      charity = Charity.find_by(shop: shop_name)
      template = params['template']
      body = email_body(template, charity, donation)

      {email_body: body}.to_json

    rescue Liquid::SyntaxError => e
      {email_body: e.message}.to_json
    end
  end

  # send a test email to the user
  get '/test_email' do
    shopify_session do |shop_name|
      donation = mock_donation(shop_name)
      charity = Charity.find_by(shop: shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      charity.assign_attributes(charity_params(params))

      if params['email_template'].present?
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf, params['email_to'])
      elsif params['update_email_template'].present?
        original_donation = mock_donation(shop_name)
        original_donation.assign_attributes({status: 'void'})
        donation.original_donation = original_donation
        donation.status = 'update'
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_updated_receipt(shopify_shop, charity, donation, receipt_pdf, params['email_to'])
      elsif params['void_email_template'].present?
        donation.assign_attributes({status: 'void'})
        receipt_pdf = render_pdf(shopify_shop, charity, donation)
        deliver_void_receipt(shopify_shop, charity, donation, receipt_pdf, params['email_to'])
      end

      status 200

    rescue Liquid::SyntaxError => e
      status 500
    end
  end

  # render a preview of the user edited pdf template
  post '/preview_pdf' do
    shopify_session do |shop_name|
      donation = mock_donation(shop_name)
      charity = Charity.find_by(shop: shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      charity.assign_attributes({pdf_template: params['template']})

      if params['status'] == 'resent'
        donation.assign_attributes({status: 'resent'})
      elsif params['status'] == 'update'
        donation.assign_attributes({status: 'update'})
        original_donation = mock_donation(shop_name)
        original_donation.assign_attributes({status: 'void'})
        donation.original_donation = original_donation
      elsif params['status'] == 'void'
        donation.assign_attributes({status: 'void'})
      end

      receipt_pdf = render_pdf(shopify_shop, charity, donation)
      content_type 'application/pdf'
      receipt_pdf

    rescue Liquid::SyntaxError => e
      content_type 'application/text'
      e.message
    end
  end

  # export donations
  post '/export' do
    shopify_session do |shop_name|
      email_to = params['email_to']
      start_date = Date.parse(params['start_date'])
      end_date = Date.parse(params['end_date'])

      ExportCsvJob.perform_async(shop_name, email_to, start_date, end_date)

      flash[:notice] = "CSV will be emailed to #{email_to}"
      redirect '/?tab=donations'
    end
  end

  private

  def mock_donation(shop_name)
    Donation.new(
      id: rand(1000),
      shop: shop_name,
      order: mock_order.to_json,
      order_id: mock_order['id'],
      order_number: mock_order['name'],
      donation_amount: 20.00
    )
  end

  def mock_order
    @mock_order ||= JSON.parse( File.read(File.join('test', 'fixtures/order.json')) )
    @mock_order['created_at'] = Time.now
    @mock_order
  end
end
