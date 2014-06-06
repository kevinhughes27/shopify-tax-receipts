require './lib/base'
require './lib/pdf_generator'
require 'pony'

class Charity < ActiveRecord::Base
  belongs_to :shop
  validates_presence_of :name, :charity_id
end

class Product < ActiveRecord::Base
  belongs_to :shop
  validates_presence_of :product_id
  validates_uniqueness_of :product_id, scope: :shop
end

class SinatraApp < ShopifyApp

  # Home page
  get '/' do
    shopify_session do |shop_name|
      @shop = Shop.find_by(name: shop_name)
      @charity = Charity.find_by(shop: @shop)
      @products = Product.where(shop: @shop)
      erb :home
    end
  end

  post '/order.json' do
    webhook_session do |shop, order|
      donation_product_ids = Product.where(shop: shop).pluck(:product_id)
      donations = []
      order["line_items"].each do |item|
        if donation_product_ids.include? item["product_id"]
          donations << item["price"].to_f * item["quantity"].to_i
        end
      end

      unless donations.empty?
        charity = Charity.find_by(shop: shop)
        shopify_shop = ShopifyAPI::Shop.current

        donation_amount = donations.sum

        pdf_generator = PdfGenerator.new(shop: shopify_shop,
                                         order: order,
                                         donation_amount: donation_amount,
                                         charity_id: charity.charity_id)
        receipt_pdf = pdf_generator.generate

        Pony.mail to: order["customer"]["email"],
                  from: "no-reply@#{shopify_shop.domain}",
                  subject: "Donation receipt for #{shopify_shop.name}",
                  attachments: {"tax_receipt.pdf" => receipt_pdf},
                  body: erb(:receipt_email, layout: false, locals: {order: order, shop: shop})
      end
    end
  end

  post '/charity' do
    shopify_session do |shop_name|
      shop = Shop.find_by(name: shop_name)
      params.merge!(shop: shop)

      charity = Charity.new(params)

      if charity.save
        flash[:notice] = "Charity Information Saved"
      else
        flash[:error] = "Error Saving Charity Information"
      end

      redirect '/'
    end
  end

  put '/charity' do
    shopify_session do |shop_name|
      shop = Shop.find_by(name: shop_name)
      charity = Charity.find_by(shop: shop)

      if charity.update_attributes(params)
        flash[:notice] = "Charity Information Saved"
      else
        flash[:error] = "Error Saving Charity Information"
      end

      redirect '/'
    end
  end

  get '/products' do
    shopify_session do |shop_name|
      shop = Shop.find_by(name: shop_name)

      params["ids"].each do |id|
        product = Product.new(shop: shop, product_id: id)
        product.save
      end

      redirect '/'
    end
  end

  private

  def install
    shopify_session do
      params = YAML.load(File.read("config/app.yml"))

      order_webhook = ShopifyAPI::Webhook.new(params["order_webhook"])
      uninstall_webhook = ShopifyAPI::Webhook.new(params["uninstall_webhook"])

      # create the order webhook if not present
      unless ShopifyAPI::Webhook.find(:all).include?(order_webhook)
        order_webhook.save
      end

      # create the uninstall webhook if not present
      unless ShopifyAPI::Webhook.find(:all).include?(uninstall_webhook)
        uninstall_webhook.save
      end
    end
    redirect '/'
  end

  def uninstall
    webhook_session do |shop, params|
      Charity.where(shop: shop).destroy_all
      Product.where(shop: shop).destroy_all
      shop.destroy
    end
  end

end
